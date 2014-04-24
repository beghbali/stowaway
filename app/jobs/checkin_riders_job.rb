require 'pusher-client'

class CheckinRidersJob
  include HTTParty

  @queue = :checkin_queue

  def self.perform(ride_id)
    ride = Ride.find(ride_id)
    raise "ride not found: #{ride_id}" if ride.nil?

    socket = PusherClient::Socket.new(ENV['PUSHER_KEY'], secret: ENV['PUSHER_SECRET'], encrypted: true)
    socket.subscribe(ride.location_channel_name, ENV['PUSHER_SERVER_USER_ID'])
    end_autocheckin_at = 2.minutes.from_now
    Rails.logger.info "[AUTOCHECKIN] subscribed to #{ride.location_channel_name}: auto-closes at {end_autocheckin_at}"
    socket[ride.location_channel_name].bind('client-location-update') do |json|
      Rails.logger.info "[AUTOCHECKIN] data:#{json}"
      data = JSON.parse(json).with_indifferent_access
      request = ::Request.find_by_public_id(data[:request_public_id])
      Rails.logger.info "[AUTOCHECKIN] updating lat lng #{data[:lat]}, #{data[:long]}"
      request.update(last_lat: data[:lat], last_lng: data[:long]) unless request.checkedin? || request.missed?
      Rails.logger.info "[AUTOCHECKIN] disconnect? #{ride.closed?}"
      ride.close if Time.now >= end_autocheckin_at
      socket.disconnect if ride.closed?
    end
    socket.connect
  end

  def self.authenticate(socket_id, channel)
    Rails.logger.debug "Authenticating"
    Rails.logger.debug(post "#{ENV[SERVER_ADDRESS]}/pusher/#{ENV['PUSHER_SERVER_USER_ID']}/auth", {channel_name: channel, socket_id: socket_id})
  end
end