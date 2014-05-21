class InitiateRequestJob

  @queue = :initiate
  @retry_exceptions = [Timeout::Error, Errno::ECONNREFUSED, Errno::ECONNRESET]

  def self.perform(request_id)
    request = Request.find(request_id)
    unless request.nil?
      request.initiate
    end
  end
end