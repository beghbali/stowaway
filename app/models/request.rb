class Request < ActiveRecord::Base
  include Notify::Notifiable
  acts_as_paranoid

  STATUSES = %w(outstanding matched fulfilled cancelled timedout)
  DEVICE_TYPES = %w(ios android)
  PICKUP_RADIUS = 0.3
  DROPOFF_RADIUS = 0.5
  DESIGNATIONS =  %w(stowaway captain)

  belongs_to :user
  belongs_to :ride
  validates :status, inclusion: { in: STATUSES }
  validates :device_type, inclusion: { in: DEVICE_TYPES }

  after_create :match_request
  after_save :notify_riders, if: :status_changed?

  geocoded_by :pickup_address, latitude: :pickup_lat, longitude: :pickup_lng
  geocoded_by :dropoff_address, latitude: :dropoff_lat, longitude: :dropoff_lng

  delegate :device_token, to: :user
  delegate :device_type, to: :user

  STATUSES.each do |status|
    scope status, -> { where(status: status) }
  end

  scope :same_route, ->(as) {
      near([as.pickup_lat, as.pickup_lng], PICKUP_RADIUS, latitude: :pickup_lat, longitude: :pickup_lng).
      near([as.dropoff_lat, as.dropoff_lng], PICKUP_RADIUS, latitude: :dropoff_lat, longitude: :dropoff_lng).
      where.not(:id => as.id)
    }

  DESIGNATIONS.each do |designation|
    scope designation.pluralize, -> { where(designation: designation) }
  end

  def match_request
      unless match_with_outstanding_requests
      match_with_existing_rides
    end
  end

  def match_with_outstanding_requests
    matches = self.class.outstanding.order(created_at: :asc).same_route(self).limit(Ride::CAPACITY - 1)

    if matches.any?
      ride = Ride.create
      (matches + [self]).map{ |rider| rider.add_to(ride) }
    end
    ride
  end

  def match_with_existing_rides
    matches = self.class.matched.same_route(self).select("requests.*, COUNT(requests.ride_id) as spaces_taken").order(spaces_taken: :asc)

    if matches.any?
      ride = matches.first.ride
      self.add_to(ride)
    end
    ride
  end

  def add_to(ride)
    self.status = 'matched'
    self.designation = :stowaway if ride.has_captain?
    self.ride = ride
    save
  end

  def notify_riders
    unless self.ride.nil?
      self.ride.riders.each do |rider|
        rider.notify(other: { ride: self.ride.as_json })
      end
    end
  end

  def as_json(options = {})
    if options[:format] == :notification
      super(only: [:status, :designation]).merge(user_public_id: self.user.public_id)
    else
      super(except: [:id, :user_id])
    end
  end
end
