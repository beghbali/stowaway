require 'pusher-client'

class CloseRideJob
  include HTTParty

  @queue = :close_ride

  def self.perform(ride_id)
    ride = Ride.find(ride_id)
    raise "ride not found: #{ride_id}" if ride.nil?

    ride.close
  end
end