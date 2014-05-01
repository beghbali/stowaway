class InitiateRequestJob

  @queue = :initiate

  def self.perform(request_id)
    request = Request.find(request_id)
    unless request.nil?
      request.initiate
    end
  end
end