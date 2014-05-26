class NotificationJob

  @queue = :notifications
  @retry_exceptions = [Timeout::Error, Errno::ECONNREFUSED, Errno::ECONNRESET]

  def self.perform(klass, id, options)
    notifiable = klass.where(id: id).first

    unless notifiable.nil?
      notifiable.notify!(options)
    end
  end
end