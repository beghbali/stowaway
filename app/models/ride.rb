class Ride < ActiveRecord::Base
  include Notify::Notifier
  include PublicId

  acts_as_paranoid

  has_public_id
  CAPACITY = 4
  CHECKIN_PROXIMITY = 0.025

  has_many :requests, autosave: true
  has_many :riders, through: :requests, source: :user
  has_many :stowaways, -> { stowaways }, class_name: 'Request'
  has_one :captain, -> { captains }, class_name: 'Request'

  before_create :generate_location_channel
  before_destroy :notify_riders

  def has_captain?
    !self.captain.nil?
  end

  def as_json(options = {})
    reqs = options[:requests] || self.requests

    if options[:format] == :notification
      super(only: [:public_id])
    else
      super(except: [:created_at, :updated_at, :id], methods: :status).merge(requests: reqs.map{|req| req.as_json })
    end
  end

  def status
    self.requests.first.status
  end

  def generate_location_channel
    self.location_channel = "#{SecureRandom.hex(10)}"
  end

  def finalize
    captain = determine_captain
    captain.update(designation: :captain, status: 'fulfilled')
    (self.requests - [captain]).each do |request|
      request.status = 'fulfilled'
      request.designation = :stowaway
      request.save
    end
    self.suggested_dropoff_address, self.suggested_dropoff_lat, self.suggested_dropoff_lng = determine_suggested_dropoff_location
    self.suggested_pickup_address, self.suggested_pickup_lat, self.suggested_pickup_lng = determine_suggested_pickup_location
    save
  end

  def determine_captain
    self.requests.reduce([]) do |list, request|
      list << [request, self.requests.select("AVG(#{Request.distance_from_sql(request, latitude: :pickup_lat, longitude: :pickup_lng)}) as average_distance").first.average_distance]
    end.sort {|a,b| a[1] <=> b[1] }.first[0]
  end

  def determine_suggested_dropoff_location
    lat_lng = Geocoder::Calculations.geographic_center(self.requests.pluck(:dropoff_lat, :dropoff_lng))
    ["suggested dropoff location"] + lat_lng
  end

  def determine_suggested_pickup_location
    [self.captain.pickup_address, self.captain.pickup_lat, self.captain.pickup_lng]
  end

  def finalized?
    !self.requests.matched.any?
  end

  def notify_riders
    self.riders.each do |rider|
      rider.notify(other: self.as_json(format: :notification)) unless rider.cannot_be_notified?
    end
  end

  def checkin(rider)
    request = rider.request_for(self)
    raise ArgumentError.new("user is not part of this ride") if request.nil?

    request.update(status: 'checkedin') if request.distance_to(self.captain) <= CHECKIN_PROXIMITY
  end

end