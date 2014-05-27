class InitiateRequestJob

  @queue = :initiate
  @retry_exceptions = [Timeout::Error, Errno::ECONNREFUSED, Errno::ECONNRESET]

  def self.perform(request_id)
    request = Request.where(id: request_id).first
    unless request.nil?
      request.initiated
    end
  end
end