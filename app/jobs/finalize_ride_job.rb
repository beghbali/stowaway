class FinalizeRideJob

  @queue = :finalize
  @retry_exceptions = [Timeout::Error, Errno::ECONNREFUSED, Errno::ECONNRESET]

  def self.perform(ride_id)
    ride = Ride.find(ride_id)
    ride.finalize
  rescue ActiveRecord::RecordNotFound
    Rails.logger.info "WARNING: finalization failed. ride #{ride_id} not found"
  end
end