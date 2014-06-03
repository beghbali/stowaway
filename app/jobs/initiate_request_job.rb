class InitiateRequestJob

  @queue = :initiate
  @retry_exceptions = [Timeout::Error, Errno::ECONNREFUSED, Errno::ECONNRESET]

  def self.perform(request_id)
    request = Request.where(id: request_id).first
    unless request.nil?
      request.initiated!
      Rails.logger.info "Request #{request.public_id} initiated"
    end
  end
end