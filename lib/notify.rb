module Notify
  module Utils
    def notification(options = {})
      alert, sound = notification_options(options)
      {
        alert: alert,
        sound: sound
      }
    end

    def nullified_notification_options(options = {})
      alert, sound = yield(alert, sound, options) if block_given?

      alert = nillify_blank(alert)
      sound = nillify_blank(sound)

      [alert, sound]
    end

    private
    def nillify_blank(str)
      str.blank? ? nil : str
    end
  end

  module Notifier

    def notify(targets, options = {})
      targets.map{ |target| target.notify(options)}
    end
  end

  module Notifiable
    class MisconfiguredDeviceError < ArgumentError; end

    def cannot_be_notified?
      self.device_token.blank? || self.device_type.blank?
    end

    def notify(options = {})
      Resque.enqueue(NotificationJob, self.class.to_s, self.public_id, options)
    end

    def notify!(options = {})
      return if cannot_be_notified?
      options = options.with_indifferent_access

      Rails.logger.info "NOTIFICATION: #{options} TO: #{self.try(:device_token)}, #{self.device_type.to_sym == :ios}, #{self.device_type}"

      if self.device_type.to_sym == :ios
        Rails.logger.info "APNS: #{APNS::Notification.new(self.device_token, options).packaged_message}"
        APNS.send_notification(self.device_token, options)
      else
        # GCM.send_notification(self.device_token, options[:other])
      end
    rescue Exception => e
      Rails.logger.error("NOTIFICATION: FAILED #{e.message}")
    end
  end
end