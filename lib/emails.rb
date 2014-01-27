module Emails

  def email_service
    @email_service ||= const_get(self.provider.camelize).new(self.email, self.send("#{self.provider}_access_token"))
  end

  def unprocessed_emails(options={})
    @email_service.emails({after: self.last_processed_email_sent_at || Time.at(0), from: ReceiptParser.supported_senders}.merge(options))
  end

  class Gmail
    attr_accessor :gmail

    def initialize(email, auth_token)
      gmail = Gmail.connect(:xoauth2, "email@domain.com", token: auth_token)
    end

    def emails(options={})
      gmail.inbox.emails(options)
    end
  end
end