class NotificationJob

  @queue = :notifications
  @retry_exceptions = [Timeout::Error, Errno::ECONNREFUSED, Errno::ECONNRESET]

  def self.perform(klass, public_id, options)
    notifiable = klass.constantize.where(public_id: public_id).first

    Rails.logger.info "About to notify: #{notifiable.try(:public_id)}"

    unless notifiable.nil?
      notifiable.notify!(options)
    end
  end
end