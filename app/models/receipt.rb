class Receipt
  def self.create_from_email(email)
    pp email.subject
    pp email.text_part.body.to_s
  end
end