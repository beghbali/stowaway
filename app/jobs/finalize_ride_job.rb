class FinalizeRideJob

  @queue = :finalize

  def self.perform(ride_id)
    ride = Ride.find(ride_id)
    unless ride.nil?
      ride.finalize
    end
  end
end