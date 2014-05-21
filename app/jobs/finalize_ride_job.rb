class FinalizeRideJob

  @queue = :finalize
  @retry_exceptions = [Timeout::Error, Errno::ECONNREFUSED, Errno::ECONNRESET]

  def self.perform(ride_id)
    ride = Ride.find(ride_id)
    unless ride.nil?
      ride.finalize
    end
  end
end