class CloseRideJob

  @queue = :close_ride
  @retry_exceptions = [Timeout::Error, Errno::ECONNREFUSED, Errno::ECONNRESET]

  def self.perform(ride_id)
    ride = Ride.where(id: ride_id).first
    if ride.present?
      Rails.logger.info "[AUTOCHECKIN] closing ride #{ride_id}"
      ride.close
    end
  end
end