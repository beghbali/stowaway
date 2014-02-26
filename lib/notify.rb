module Notify
  module Notifier

    def notify(targets, options = {})
      targets.map{ |target| target.notify(options)}
    end
  end

  module Notifiable
    class MisconfiguredDeviceError < ArgumentError; end

    def notify(options = {})
      raise MisconfiguredDeviceError.new("no device token specified") if self.device_token.blank?
      raise MisconfiguredDeviceError.new("no device type specified") if self.device_type.blank?

      if device_type.to_sym == :ios
        APNS.send_notification(self.device_token, options)
      else
        # GCM.send_notification(self.device_token, options[:other])
      end
    end
  end
end