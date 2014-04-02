require 'pusher-client'

class CheckinRidersJob
  include HTTParty

  @queue = :checkin_queue

  def self.perform(ride_id)
    ride = Ride.find(ride_id)
    raise "ride not found: #{ride_id}" if ride.nil?

    socket = PusherClient::Socket.new(ENV['PUSHER_KEY'], secret: ENV['PUSHER_SECRET'], encrypted: true)
    socket.subscribe(ride.location_channel_name, ENV['PUSHER_SERVER_USER_ID'])

    socket[ride.location_channel_name].bind('client-location-update') do |json|
      Rails.logger.debug "DATA:#{json}"
      data = JSON.parse(json).with_indifferent_access
      request = ::Request.find_by_public_id(data[:request_public_id])
      Rails.logger.debug "updating lat lng #{data[:lat]}, #{data[:long]}"
      request.update(last_lat: data[:lat], last_lng: data[:long])
      Rails.logger.debug "disconnect? #{ride.closed?}"
      socket.disconnect if ride.closed?
    end
    socket.connect
  end

  def self.authenticate(socket_id, channel)
    Rails.logger.debug "Authenticating"
    Rails.logger.debug(post "#{ENV[SERVER_ADDRESS]}/pusher/#{ENV['PUSHER_SERVER_USER_ID']}/auth", {channel_name: channel, socket_id: socket_id})
  end
end