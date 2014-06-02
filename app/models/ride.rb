class Ride < ActiveRecord::Base
  include Notify::Notifier
  include Notify::Utils
  include PublicId

  acts_as_paranoid

  has_public_id
  CAPACITY = 4
  CHECKIN_PROXIMITY = 0.007
  MIN_CAPTAIN_VICINITY_COUNT = -5
  MAX_CAPTAIN_VICINITY_COUNT = 5
  PRESUMED_SPEED = 25 #mph
  BASE_FEE = 1.00 #dollars
  CAPTAIN_NOTIFICATION_TIME = 5.minutes #how long before the ride to remind them (if scheduled)
  STOWAWAY_NOTIFICATION_TIME = 10.minutes

  has_many :requests, -> { available }
  has_many :riders, through: :requests, source: :user
  has_many :stowaways, -> { stowaways }, class_name: 'Request'
  has_one :captain, -> { captains }, class_name: 'Request'
  belongs_to :receipt

  before_create :generate_location_channel
  before_destroy -> { stop_checkin && notify_riders('ride_cancelled') }
  after_destroy :reset_requests
  after_destroy :delete_reminders
  after_save :generate_stowaway_receipts, if: :receipt_id_changed?

  scope :unreconciled, -> { where(receipt_id: nil) }

  def has_captain?
    !self.captain.nil?
  end

  def as_json(options = {})
    reqs = options[:requests] || self.requests

    if options[:format] == :notification
      super(only: [:public_id]).merge(status: options[:status] || self.status)
    else
      super(except: [:created_at, :updated_at, :id, :suggested_pickup_time]).merge(
        suggested_pickup_time: suggested_pickup_time.try(:to_time).try(:to_f),
        status: options[:status] || self.status,
        timeout: timeout_notification,
        requests: reqs.map{|req| req.as_json })
    end
  end

  def status
    self.requests.first.status
  end

  def location_channel_name
    "private-#{location_channel}"
  end

  def generate_location_channel
    self.location_channel = "#{SecureRandom.hex(10)}"
  end

  def finalize
    captain = determine_captain
    captain.update(designation: :captain, status: 'fulfilled')
    (self.requests - [captain]).map { |request| request.update(status: 'fulfilled', designation: :stowaway) }
    set_pickup_to_captains
    save
    initiate
  end

  def request_added(request)
    update_ride_route!
    update_ride_time!
    schedule_finalization
  end

  def update_ride_route!
    self.suggested_dropoff_address, self.suggested_dropoff_lat, self.suggested_dropoff_lng = determine_suggested_dropoff_location
    self.suggested_pickup_address, self.suggested_pickup_lat, self.suggested_pickup_lng = determine_suggested_pickup_location
    save
  end

  def determine_suggested_pickup_time
    request_times = requests.order(requested_for: :desc).pluck(:requested_for)
    request_times[request_times.count/2]
  end

  def update_ride_time!
    update(suggested_pickup_time: determine_suggested_pickup_time)
  end

  def set_pickup_to_captains
    self.suggested_pickup_address, self.suggested_pickup_lat, self.suggested_pickup_lng = captain.try(:pickup_address), captain.try(:pickup_lat), captain.try(:pickup_lng)
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
    lat_lng = Geocoder::Calculations.geographic_center(self.requests.pluck(:pickup_lat, :pickup_lng))
    ["suggested pickup location"] + lat_lng
  end

  def finalized?
    !self.requests.matched.any?
  end

  def notify_riders(status)
    self.riders.each do |rider|
      alert, sound = notification_options(status)
      data = self.as_json(format: :notification, status: status)
      data.merge!('public_id' => nil) if status == 'ride_cancelled'
      rider.notify(alert: alert, sound: sound, other: data)
    end
  end

  def reset_requests
    self.requests.available.map(&:outstanding!)
  end

  def start_checkin
    Resque.enqueue(CheckinRidersJob, self.id)
  end

  def stop_checkin
    Rails.logger.debug "Stop checking in: #{self.location_channel_name}, #{self.public_id}"
    Resque::Job.destroy(:autocheckin, CheckinRidersJob, self.id)
  end

  def close
    stop_checkin
    collect_payments
  end

  def closed?
    !self.requests.unclosed.any?
  end

  def anticipated_end
    captain.checkedin_at + (distance/PRESUMED_SPEED).hours
  end

  def distance
    Geocoder::Calculations.distance_between([suggested_pickup_lat, suggested_pickup_lng],
                                            [suggested_dropoff_lat, suggested_dropoff_lng])
  end

  def cancellations
    requests.only_deleted.order(updated_at: :asc)
  end

  def timeout_notification
    {
      alert: I18n.t('notifications.ride.timeout.alert'),
      sound: I18n.t('notifications.ride.timeout.sound')
    }
  end

  def collect_payments
    Resque.enqueue_at(self.anticipated_end + 5.minutes, ReconcileReceiptsJob, self.public_id)
  end

  def find_receipt
    Receipt.rideshares.for(self).first
  end

  #find receipt by closeness to start and closeness to end and date and closeness to time
  #get amount and divide by number of checkedin. charge each stowaway include our charge. generate receipt
  #pay captain by adding credits.
  #charges should first take credits and charge balance to card
  #link each ride to the reconciled receipt and each request to the generated stowaway receipt.
  #reconcile stowaway receipts
  def reconcile_receipt
    self.class.transaction do
      receipt = find_receipt
      unless receipt.blank?
        self.receipt = receipt
        save
        self.captain.rider.credit(self.cost)

        self.riders.each do |rider|
          request = rider.request_for(self)
          charges = self.cost_of(rider) + fee
          cost = request.coupon.present? ? request.coupon.apply(charges) : charges
          charged, credits_used, charge_ref = rider.charge(cost.round(2), request)
          request.create_payment!(amount: cost, credits_used: credits_used, credit_card_charge: charged, fee: fee, reference: charge_ref)
        end
      end
    end
  end

  def fee
    BASE_FEE
  end

  #same cost for everyone
  def cost_of(user)
    self.riders.exists?(id: user.id) && self.cost/self.riders.count
  end

  def pickup_location
    [suggested_pickup_lat, suggested_pickup_lng]
  end

  def reconciled?
    !receipt_id.nil?
  end

  def cost
    receipt && receipt.total_amount
  end

  def generate_stowaway_receipts
    self.riders.each do |rider|
    end
  end

  def to_s(format=nil)
    if format.try(:to_sym) == :charge
      I18n.t('models.ride.format.charge', pickup: self.suggested_pickup_address)
    end
  end

  def suggested_pickup_time
    self[:suggested_pickup_time] || determine_suggested_pickup_time
  end

  def schedule_finalization
    duration = requests.where.not(duration: nil).first.try(:duration)
    if duration.present?
      Resque::Job.destroy('finalize', FinalizeRideJob, self.id)
      Resque.enqueue_at(self.suggested_pickup_time - duration, FinalizeRideJob, self.id)
    end
  end

  def initiate
    requests.each do |request|
      request.scheduled? ? Resque.enqueue_at(self.suggested_pickup_time - self.class.const_get("#{request.designation.upcase}_NOTIFICATION_TIME"), InitiateRequestJob, request.id) : request.initiate!
    end
  end

  def delete_reminders
    Resque::Job.destroy('finalize', FinalizeRideJob, self.id)
    requests.with_deleted.each do |request|
      Resque::Job.destroy('initiate', InitiateRequestJob, request.id)
    end
  end

  protected
  def notification_options(status)
    nullified_notification_options do |options|
      if status == 'ride_cancelled'
        who_canceled = self.captain.present? ? 'cancelled_by_captain' : 'cancelled'
        alert = I18n.t("notifications.ride.#{who_canceled}.alert", name: self.captain && self.captain.user.first_name)
        sound = I18n.t("notifications.ride.#{who_canceled}.sound")
      end
      [alert, sound]
    end
  end
end
