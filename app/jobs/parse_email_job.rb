class ParseEmailJob
  extend Resque::Plugins::Retry
  @queue = :email_parser
  @retry_exceptions = [Timeout::Error, Errno::ECONNREFUSED, Errno::ECONNRESET]

  def self.perform(user_public_id, message)
    user = User.find_by_public_id(user_public_id)
    return if user.nil?
    email = Mail::Message.new(YAML.load(message))

    Receipt.transaction do
      receipt = Receipt.build_from_email(email)
      receipt.user_id = user.id
      receipt.save!
      user.last_processed_email_sent_at = [user.last_processed_email_sent_at || Time.at(0), email.date].max
      user.save
    end
  end
end