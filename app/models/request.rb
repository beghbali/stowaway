class Request < ActiveRecord::Base
  include PublicId

  has_public_id

  acts_as_paranoid

  STATUSES = %w(outstanding matched fulfilled cancelled checkedin missed)
  PICKUP_RADIUS = 0.3
  DROPOFF_RADIUS = 0.5
  DESIGNATIONS =  %w(stowaway captain)

  belongs_to :user
  belongs_to :ride
  has_many :riders, through: :ride
  validates :status, inclusion: { in: STATUSES }

  before_create :match_request
  after_create :finalize, if: :can_finalize?
  before_destroy :cancel
  after_destroy :cancel_ride, if: -> { self.ride && !self.ride.marked_for_destruction? && (self.captain? || self.ride.requests.count <= 2) }

  geocoded_by :pickup_address, latitude: :pickup_lat, longitude: :pickup_lng
  geocoded_by :dropoff_address, latitude: :dropoff_lat, longitude: :dropoff_lng

  delegate :device_token, to: :user
  delegate :device_type, to: :user
  delegate :finalize, to: :ride
  delegate :notify_riders, to: :ride

  scope :same_route, ->(as) {
      near([as.pickup_lat, as.pickup_lng], PICKUP_RADIUS, latitude: :pickup_lat, longitude: :pickup_lng).
      near([as.dropoff_lat, as.dropoff_lng], PICKUP_RADIUS, latitude: :dropoff_lat, longitude: :dropoff_lng).
      where.not(:id => as.id)
    }

  DESIGNATIONS.each do |designation|
    scope designation.pluralize, -> { where(designation: designation) }

    define_method "#{designation}?" do
      self.designation.to_s == designation
    end
  end

  STATUSES.each do |status|
    scope status, -> { where(status: status) }

    define_method "#{status}?" do
      self.status.to_s == status
    end
  end

  def match_request
    ride = match_with_outstanding_requests || match_with_existing_rides
    notify_riders('matched', self) unless ride.nil?
  end

  def match_with_outstanding_requests
    matches = self.class.outstanding.order(created_at: :asc).same_route(self).limit(Ride::CAPACITY - 1)

    if matches.any?
      self.create_ride
      (matches + [self]).map{ |rider| rider.add_to(self.ride) }
    end
    ride
  end

  def match_with_existing_rides
    matches = self.class.matched.same_route(self).
                select("requests.*, COUNT(requests.ride_id) as spaces_taken").
                having('COUNT(requests.ride_id) < ?', Ride::CAPACITY).
                order('spaces_taken ASC')

    if matches.any?
      ride = matches.first.ride
      self.add_to(ride)
    end
    ride
  end

  def add_to(ride)
    self.status = 'matched'
    self.ride = ride
    save unless new_record?
  end

  def full_house?
    self.riders.count == Ride::CAPACITY
  end

  def can_finalize?
    full_house? && !self.ride.finalized?
  end

  def requested_at
    self.created_at.to_i
  end

  def cancel_ride
    self.ride.destroy
  end

  def cancel
    self.update!(status: 'cancelled')
    notify_riders('cancelled', self) unless self.ride.nil? || self.ride.marked_for_destruction?
  end

  def as_json(options = {})
    if options[:format] == :notification
      super(only: [:public_id, :status, :designation], methods: :requested_at).merge(user_public_id: self.user.public_id, uid: self.user.uid)
    else
      super(except: [:id, :user_id, :ride_id], methods: :requested_at).
        merge(created_at: created_at.to_i, updated_at: updated_at.to_i, user_public_id: self.user.public_id, uid: self.user.uid, ride_public_id: self.ride.try(:public_id))
    end
  end
end
