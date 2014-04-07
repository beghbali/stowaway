class Receipt < ActiveRecord::Base
  belongs_to :user
  validate :did_not_generate_same_receipt_before

  RIDESHARES = %w(Uber)

  scope :rideshare, -> { where(generated_by: RIDESHARES)}
  scope :for, ->(ride) { where(ride_requested_at: (ride.created_at..ride.created_at + 20.minutes)).near(ride.pickup_location)}
  #ride requested at within 15 minutes + geocoded pickup location/dropoff location within 200 ft of the ride
  def self.build_from_email(email)
    parser = ReceiptParser.parser_for(email)
    raise ReceiptParser::UnknownSenderError.new(mail.from) if parser.nil?

    parsed_email = parser.new(email).parse
    self.new(parsed_email)
  end

  def around_requested_at
    2.minutes.ago(self.ride_requested_at)..2.minutes.from_now(self.ride_requested_at)
  end


  def did_not_generate_same_receipt_before
    errors.add(:base, "duplicate receipt") if self.duplicate?
  end

  def duplicate?
    self.class.exists?(billed_to: self.billed_to,
      total_amount: self.total_amount,
      ride_requested_at: self.around_requested_at)
  end
end