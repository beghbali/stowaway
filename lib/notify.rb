module Notify
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
      puts options
      if device_type.to_sym == :ios
        APNS.send_notification(self.device_token, options)
      else
        # GCM.send_notification(self.device_token, options[:other])
      end
    end
  end
end