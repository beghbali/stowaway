class Receipt < ActiveRecord::Base
  def self.create_from_email(email)
    parser = ReceiptParser.parser_for(email)
    raise ReceiptParser::UnknownSenderError.new(mail.from) if parser.nil?

    parsed_email = parser.new(email).parse
    self.create(parsed_email) unless duplicate?(parsed_email)
  end

  def self.duplicate?(attributes)
    self.exists?(billed_to: attributes[:billed_to],
      total_amount: attributes[:total_amount],
      ride_requested_at: duplication_time_range(attributes[:ride_requested_at]))
  end

  def self.duplication_time_range(time)
    2.minutes.ago(time)..2.minutes.from_now(time)
  end
end