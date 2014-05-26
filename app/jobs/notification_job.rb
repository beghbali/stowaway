class NotificationJob

  @queue = :notifications
  @retry_exceptions = [Timeout::Error, Errno::ECONNREFUSED, Errno::ECONNRESET]

  def self.perform(klass, id, options)
    notifiable = klass.constantize.where(id: id).first

    Resque.logger.info "About to notify: #{notifiable.try(:public_id)}"

    unless notifiable.nil?
      notifiable.notify!(options)
    end
  end
end