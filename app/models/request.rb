class Request < ActiveRecord::Base
  include PublicId

  has_public_id

  acts_as_paranoid

  STATUSES = %w(outstanding matched fulfilled cancelled checkedin missed)
  CLOSED_STATUSES = %w(missed checkedin)
  PICKUP_RADIUS = 0.3
  DROPOFF_RADIUS = 0.5
  DESIGNATIONS =  %w(stowaway captain)

  belongs_to :user
  belongs_to :ride
  has_many :riders, through: :ride
  validates :status, inclusion: { in: STATUSES }

  after_create :match_request, unless: :dont_match   #TODO: see if this can be done after commit in case the client requests ride for things to be resolved already
  after_create :finalize, if: :can_finalize?
  after_save :record_vicinity, if: -> { self.last_lat_changed? || last_lng_changed? }
  before_destroy :cancel
  after_destroy :cancel_ride, if: :should_cancel_ride?

  geocoded_by :pickup_address, latitude: :pickup_lat, longitude: :pickup_lng
  geocoded_by :dropoff_address, latitude: :dropoff_lat, longitude: :dropoff_lng

  delegate :device_token, to: :user
  delegate :device_type, to: :user
  delegate :finalize, to: :ride

  scope :checkinable, -> { where('vicinity_count >= ?', Ride::MIN_CAPTAIN_VICINITY_COUNT) }
  scope :uncheckinable, -> { where('vicinity_count < ?', Ride::MIN_CAPTAIN_VICINITY_COUNT) }
  scope :active, -> { where(status: %w(outstanding matched fulfilled))}
  scope :available, -> { where(deleted_at: nil) }
  scope :unclosed, -> { where('status NOT IN (?)', CLOSED_STATUSES)}
  scope :closed, -> { where(status: CLOSED_STATUSES)}

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

    define_method "#{status}!" do
      self.update(status: status)
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

    unless self.ride.nil?
      notify_other_riders
    end
  end

  def match_with_outstanding_requests
    matches = self.class.outstanding.order(created_at: :asc).same_route(self).limit(Ride::CAPACITY - 1)

    if matches.any?
      self.create_ride
      (matches + [self]).map{ |request| request.add_to(self.ride) }
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
    save
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

  def record_vicinity
    self.increment(:vicinity_count) if self.proximity_to(self.ride.captain) <= Ride::CHECKIN_PROXIMITY
    Rails.logger.debug("DISTANCE to captain: #{self.proximity_to(self.ride.captain)}")
    try_checkin
  end

  def try_checkin
    if self.vicinity_count >= Ride::MAX_CAPTAIN_VICINITY_COUNT
      self.ride.close
    elsif self.vicinity_count >= Ride::MIN_CAPTAIN_VICINITY_COUNT
      if self.ride.requests.uncheckinable.any?
        self.checkin
      else
        self.ride.close
      end
    end
  end

  def checkedin!
    self.update(status: 'checkedin', checkedin_at: Time.now)
  end

  def checkin
    self.checkedin!
    notify_all_riders
    pay
  end

  def pay
    Resque.enqueue_at(ride.anticipated_end + 5.minutes, ReconcileReceiptsJob, self.rider.public_id)
  end

  def missed
    self.missed!
    notify_all_riders
    self.deactivate!
  end

  def deactivate!
    self.update(deleted_at: Time.now)
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
      super(except: [:id, :user_id, :ride_id], methods: :requested_at).
        merge(created_at: created_at.to_i, updated_at: updated_at.to_i, user_public_id: self.user.public_id, uid: self.user.uid, ride_public_id: self.ride.try(:public_id))
    end
  end

  def notify(audience)
    audience.each do |request|
      alert, sound = notification_options
      request.rider.notify(alert: alert, sound: sound, other: self.ride.as_json(format: :notification, status: self.status))
    end
  end

  protected

  def should_cancel_ride?
    self.ride && (self.captain? || (self.ride.requests - [self]).count <= 1)
  end

  def notification_options
    if self.status == 'fulfilled'
      alert = I18n.t("notifications.request.fulfilled.#{designation}.alert", pickup_address: self.ride.reload.suggested_pickup_address)
      sound = I18n.t("notifications.request.fulfilled.#{designation}.sound")
    else
      alert = I18n.t("notifications.request.#{status}.alert", name: self.rider.first_name)
      sound = I18n.t("notifications.request.#{status}.sound")
    end

    [alert, sound]
  end
end
