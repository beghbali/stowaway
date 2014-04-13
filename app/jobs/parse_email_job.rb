class ParseEmailJob
  @queue = :parse_emails_queue

  def self.perform(user_public_id, message)
    user = User.find_by_public_id(user_public_id)
    return if user.nil?
    email = Mail::Message.new message['email']

    Receipt.transaction do
      debugger;2
      receipt = Receipt.build_from_email(email)
      receipt.user_id = user.id
      receipt.save!
      user.last_processed_email_sent_at = [user.last_processed_email_sent_at, email.date].max
      user.save
    end
  end
end