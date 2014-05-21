class CloseRideJob

  @queue = :close_ride
  @retry_exceptions = [Timeout::Error, Errno::ECONNREFUSED, Errno::ECONNRESET]

  def self.perform(ride_id)
    ride = Ride.find(ride_id)
    raise "ride not found: #{ride_id}" if ride.nil?
    Rails.logger.info "[AUTOCHECKIN] closing ride #{ride_id}"
    ride.close
  end
end