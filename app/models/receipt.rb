class Receipt
  def self.create_from_email(email)
    parser = ReceiptParser.parser_for(email)
    raise ReceiptParser::UnknownSenderError.new(mail.from) if parser.nil?

    pp parser.new(email).parse
    # self.create(parser.new(email).parse)
  end
end