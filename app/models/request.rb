class Request < ActiveRecord::Base
  include PublicId
  include Notify::Utils

  has_public_id

  acts_as_paranoid

  STATUSES = %w(outstanding matched fulfilled initiated cancelled checkedin missed)
  CLOSED_STATUSES = %w(missed checkedin)
  PICKUP_RADIUS = 0.3
  DROPOFF_RADIUS = 0.5
  DESIGNATIONS =  %w(stowaway captain)

  belongs_to :user
  belongs_to :ride, autosave: true
  belongs_to :receipt
  belongs_to :coupon, foreign_key: :coupon_code, primary_key: :code

  has_many :riders, through: :ride
  has_one :payment

  validates :status, inclusion: { in: STATUSES }

  before_validation :set_request_time
  before_create :match_request, unless: :dont_match
  before_save :record_vicinity, if: -> { self.last_lat_changed? || last_lng_changed? }
  before_save :apply_user_coupon
  before_save :apply_coupon, if: :coupon_code_changed?
  after_create :finalize, if: :can_finalize?
  after_create :update_routes
  after_create :notify_neighbors, if: -> { outstanding? && scheduled? }
  after_create :notify_other_riders, if: -> { status_was == 'outstanding' && ride.present? }
  after_destroy :cancel
  after_destroy :cancel_ride, if: :should_cancel_ride?

  geocoded_by :pickup_address, latitude: :pickup_lat, longitude: :pickup_lng
  geocoded_by :dropoff_address, latitude: :dropoff_lat, longitude: :dropoff_lng

  delegate :device_token, to: :user
  delegate :device_type, to: :user
  delegate :finalize, to: :ride

  scope :checkinable, -> { where('vicinity_count >= ?', Ride::MAX_CAPTAIN_VICINITY_COUNT) }
  scope :uncheckinable, -> { where('vicinity_count < ?', Ride::MAX_CAPTAIN_VICINITY_COUNT) }
  scope :active, -> { where(status: %w(outstanding matched fulfilled initiated))}
  scope :available, -> { where(deleted_at: nil) }
  scope :unclosed, -> { where('status NOT IN (?)', CLOSED_STATUSES)}
  scope :closed, -> { where(status: CLOSED_STATUSES)}
  scope :scheduled, -> { where.not(requested_for: nil) }

  scope :same_route_unscheduled, -> (as) {
    near([as.pickup_lat, as.pickup_lng], PICKUP_RADIUS, latitude: :pickup_lat, longitude: :pickup_lng).
    near([as.dropoff_lat, as.dropoff_lng], PICKUP_RADIUS, latitude: :dropoff_lat, longitude: :dropoff_lng).
    where.not(:id => as.id)
  }
  scope :same_route_scheduled, ->(as) {
    same_route_unscheduled(as).where(requested_for: (as.requested_for - as.duration)..(as.requested_for + as.duration))
  }

  scope :same_route, ->(as) {
    as.requested_for.present? && as.requested_for > Time.now ? same_route_scheduled(as) : same_route_unscheduled(as)
  }

  DESIGNATIONS.each do |designation|
    scope designation.pluralize, -> { where(designation: designation) }

    define_method "#{designation}?" do
      self.designation.to_s == designation
    end
  end

  STATUSES.each do |status|
    scope status, -> { where(status: status) }

    define_method "#{status}" do
      self.status = status
    end

    define_method "#{status}!" do
      send(status)
      save
    end

    define_method "#{status}?" do
      self.status.to_s == status
    end
  end

  attr_accessor :dont_match

  def other_requests
    self.ride.requests - [self]
  end

  def match_request
    match_with_outstanding_requests || match_with_existing_rides
  end

  def match_with_outstanding_requests
    matches = self.class.outstanding.order(created_at: :asc).same_route(self).limit(Ride::CAPACITY - 1)

    if matches.any?
      self.create_ride
      self.status = 'matched'
      matches.each do |request|
        request.update(status: 'matched', ride_id: self.ride.id)
        self.ride.request_added(request)
      end
    end
    ride
  end

  def match_with_existing_rides
    matches = self.class.matched.same_route(self).
                select("requests.*, COUNT(requests.ride_id) as spaces_taken").
                having('COUNT(requests.ride_id) < ?', Ride::CAPACITY).
                order('spaces_taken ASC')

    if matches.any?
      self.ride = matches.first.ride
      self.status = 'matched'
      self.ride.request_added(self)
    end
    ride
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
    self.cancelled!
    notify_other_riders unless self.ride.nil? || should_cancel_ride?
  end

  def last_location
    [last_lat, last_lng]
  end

  def proximity_to(another_request)
    Geocoder::Calculations.distance_between(self.last_location, another_request.last_location)
  end

  def getting_farther_from(another_request)
    current_distance = Geocoder::Calculations.distance_between(self.last_location, another_request.last_location)
    previous_distance = Geocoder::Calculations.distance_between([last_lat_was, last_lng_was], another_request.last_location)
    current_distance > previous_distance
  end

  def record_vicinity
    if self.proximity_to(self.ride.captain) <= Ride::CHECKIN_PROXIMITY
      self.increment(:vicinity_count)
    elsif getting_farther_from(self.ride.captain)
      self.decrement(:vicinity_count)
    end

    Rails.logger.debug("PROXIMITY: #{self.proximity_to(self.ride.captain)}, #{self.ride.captain.last_location}, vicinity: #{self.vicinity_count}")
    try_checkin
    self.ride.close unless self.ride.requests.unclosed.any?
  end

  def try_checkin
    if self.vicinity_count >= Ride::MAX_CAPTAIN_VICINITY_COUNT
      checkin
    elsif self.vicinity_count <= Ride::MIN_CAPTAIN_VICINITY_COUNT
      miss
    end
  end

  def fulfilled
    self.status = 'fulfilled'
    notify_rider_about([self]) if scheduled?
  end

  def initiated
    self.status = 'initiated'
    notify_rider_about([self]) if scheduled?
  end

  def checkedin
    self.status = 'checkedin'
    self.checkedin_at = Time.now
  end

  def checkedin!
    checkedin
    save
  end

  def checkin
    checkedin
    notify_all_riders
  end

  def checkin!
    checkin
    save
  end

  def miss
    self.missed
    notify_all_riders
    self.deactivate
  end

  def miss!
    miss
    save
  end


  def deactivate
    self.deleted_at = Time.now
  end

  def deactivate!
    self.update_column(:deleted_at, Time.now)
  end

  def apply_user_coupon
    self.coupon_code = user.coupon.code if self.coupon_code.nil? && user.coupon.present?
  end

  def apply_coupon
    return if coupon_code.nil?

    ride_alone! if coupon_code == 'LONERIDER'
  end

  def ride_alone!
    return nil unless self.ride.nil?
    self.create_ride
    save
    self.ride.request_added(self)
    self.ride.finalize
    self.vicinity_count = Ride::MAX_CAPTAIN_VICINITY_COUNT
    checkedin!
    self.ride.reload.close
  end

  alias_method :rider, :user

  def notify_other_riders
    notify(other_requests)
  end

  def notify_all_riders
    notify(self.ride.requests)
  end

  def notify_rider_about(others)
    others.each do |request|
      request.notify([self])
    end
  end

  def as_json(options = {})
    if options[:format] == :notification
      super(only: [:public_id, :status, :designation], methods: :requested_at).merge(user_public_id: self.user.public_id, uid: self.user.uid)
    else
      super(except: [:id, :user_id, :ride_id, :last_lat, :last_lng, :vicinity_count, :receipt_id], methods: :requested_at).
        merge(created_at: created_at.to_i, updated_at: updated_at.to_i, user_public_id: self.user.public_id,
          uid: self.user.uid, ride_public_id: self.ride.try(:public_id), notification: notification)
    end
  end

  def notify(audience)
    audience.each do |request|
      request.rider.notify(notification.merge(other: self.ride.as_json(format: :notification, status: self.status)))
    end
  end

  def to_s(format=nil)
    if format.try(:to_sym) == :charge
      self.ride && self.ride.to_s(:charge)
    end
  end

  def set_request_time
    if self.requested_for.nil?
      self.requested_for = Time.now
      self.duration = nil
    end
  end

  def scheduled?
    requested_for.present?
  end

  def notify_neighbors
    Resque.enqueue(NotifyNeighborsJob, self.id)
  end

  def pickup_location
    [self.pickup_lat, self.pickup_lng]
  end

  def dropoff_location
    [self.dropoff_lat, self.dropoff_lng]
  end

  def to_route
    Route.new(as_route)
  end

  def as_route
    {
      start_locale_id: Locale.by_location(pickup_location).first.try(:id),
      end_locale_id: Locale.by_location(dropoff_location).first.try(:id),
      added_by: 'request',
      accuracy: 5
    }
  end

  def update_routes
    route = self.rider.routes.where(as_route.except(:added_by)).first || to_route
    route.count += 1
    route.user = self.rider
    route.save
  end

  protected

  def should_cancel_ride?
    self.ride && (self.captain? || (self.ride.requests - [self]).count <= 1)
  end

  def notification_options(options = {})
    nullified_notification_options do |options|
      if self.status == 'fulfilled' || self.status == 'initiated'
        alert = I18n.t("notifications.request.#{status}.#{designation}.alert",
          pickup_address: self.ride.reload.suggested_pickup_address, minutes: self.duration)
        sound = I18n.t("notifications.request.#{status}.#{designation}.sound")
      else
        alert = I18n.t("notifications.request.#{status}.alert", name: self.rider.first_name)
        sound = I18n.t("notifications.request.#{status}.sound")
      end
      [alert, sound]
    end
  end

end
