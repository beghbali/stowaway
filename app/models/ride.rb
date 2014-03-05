class Ride < ActiveRecord::Base
  include Notify::Notifier
  include PublicId

  has_public_id
  CAPACITY = 4

  has_many :requests
  has_many :riders, through: :requests, source: :user
  has_many :stowaways, -> { stowaways }, class_name: 'Request'
  has_one :captain, -> { captains }, class_name: 'Request'

  before_create :generate_location_channel

  def has_captain?
    !self.captain.nil?
  end

  def as_json(options = {})
    reqs = options[:requests] || self.requests
    super(only: [:location_channel, :public_id]).merge(requests: reqs.map{|req| req.as_json(format: :notification) })
  end

  def generate_location_channel
    self.location_channel = "#{SecureRandom.hex(10)}"
  end

  def finalize
    captain = determine_captain

    self.requests.each do |request|
      request.status = 'fulfilled'
      request.designation = (request == captain) ? :captain : :stowaway
      request.save
    end
    debugger;2
  end

  def determine_captain
    self.requests.reduce([]) do |list, request|
      list << [request, self.requests.select("AVG(#{Request.distance_from_sql(request, latitude: :pickup_lat, longitude: :pickup_lng)}) as average_distance").first.average_distance]
    end.sort {|a,b| a[1] <=> b[1] }.first[0]
  end

  def finalized?
    !self.requests.where(status: 'outstanding').exists?
  end
end