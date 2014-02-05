class Receipt < ActiveRecord::Base
  belongs_to :user
  validate :did_not_generate_same_receipt_before

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