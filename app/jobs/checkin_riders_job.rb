require 'pusher-client'

class CheckinRidersJob
  @queue = :checkin_queue

  def self.perform(ride_id)
    ride = Ride.find(ride_id)
    raise "ride not found: #{ride_id}" if ride.nil?

    socket = PusherClient::Socket.new(ENV['PUSHER_KEY'], secret: ENV['PUSHER_SECRET'], encrypted: true)

    socket.subscribe(ride.location_channel_name, ENV['PUSHER_SERVER_USER_ID'])
    socket[ride.location_channel_name].bind('client-location-update') do |data|
      puts "DATA:#{data}"
      request = Request.find_by_public_id(data[:request_public_id])
      request.update_attributes(last_lat: data[:lat], last_lng: data[:lng])
      socket.disconnect if ride.closed?
    end
    socket.connect
  end
end