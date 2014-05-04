module Notify
  module Utils
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
      return if cannot_be_notified?
      Rails.logger.info "NOTIFICATION: #{options} TO: #{self.device_token}"
      if device_type.to_sym == :ios
        APNS.send_notification(self.device_token, options)
      else
        # GCM.send_notification(self.device_token, options[:other])
      end
    rescue Exception => e
      Rails.logger.error("NOTIFICATION: FAILED #{e.message}")
    end
  end
end