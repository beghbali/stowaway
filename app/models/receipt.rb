class Receipt < ActiveRecord::Base
  belongs_to :user
  belongs_to :payment
  has_one :request, through: :payment
  validate :did_not_generate_same_receipt_before

  geocoded_by :pickup_location, latitude: :pickup_lat, longitude: :pickup_lng

  after_validation :geocode
  after_create :email_it, if: -> { generated_by == 'Stowaway' }

  RIDESHARES = %w(Uber)
  REQUEST_TIME_PROXIMITY = 20.minutes
  scope :rideshares, -> { where(generated_by: RIDESHARES)}
  scope :for, ->(ride) { geocoded.where(billed_to: ride.captain.rider.email).where(ride_requested_at: (ride.captain.checkedin_at - REQUEST_TIME_PROXIMITY)..(ride.captain.checkedin_at + REQUEST_TIME_PROXIMITY)).near(ride.pickup_location, Request::PICKUP_RADIUS)}

  #ride requested at within 15 minutes + geocoded pickup location/dropoff location within 200 ft of the ride
  def self.build_from_email(email)
    parser = ReceiptParser.parser_for(email)
    raise ReceiptParser::UnknownSenderError.new(email.from) if parser.nil?

    parsed_email = parser.new(email.encoded).parse
    self.new(parsed_email)
  end

  def around_requested_at
    2.minutes.ago(self.ride_requested_at)..2.minutes.from_now(self.ride_requested_at)
  end


  def did_not_generate_same_receipt_before
    errors.add(:base, "duplicate receipt #{self.billed_to}, #{self.total_amount}, #{self.around_requested_at}") if self.duplicate?
  end

  def duplicate?
    self.class.where('id != ?', self.id).exists?(billed_to: self.billed_to,
      total_amount: self.total_amount,
      ride_requested_at: self.around_requested_at)
  end

  def geocode(tries=1)
    begin
      super()
      correct_pickup_location && geocode(tries+1) if pickup_lat.nil? && tries <= 3
    rescue Geocoder::OverQueryLimitError
      sleep tries*tries
      geocode(tries+1) unless tries > 3
    end
  end

  def correct_pickup_location
    if self.pickup_location =~ /^\s*\d+\s*\-\s*\d+/
      self.pickup_location = self.pickup_location.split(/^\s*\d+\s*\-/).last
    end
  end

  def email_it
    ReceiptMailer.send("#{self.payment.request.designation}_ride_receipt", self.id).deliver
  end

  def savings
    cost = self.payment && payment.request.ride.cost
    cost.nil? ? 0 : (cost - base_amount)/cost
  end

  def base_amount
    total_amount - (payment.try(:fee) || 0)
  end

  def savings_percentage
    (savings * 100).round
  end

  def credited_amount
    request.nil? ? 0.0 : (request.ride.cost - total_amount)
  end
end