module Emails

  def email_service
    @email_service ||= "Emails::#{self.email_provider.camelize}Service".constantize.new(self)
  end

  def unprocessed_emails(options={})
    email_service.emails({
      since: Net::IMAP.format_date(self.last_processed_email_sent_at || Time.at(0)),
      from: ReceiptParser.supported_senders.join,
      subject: ReceiptParser.expected_subjects.product(["OR"]).flatten.reverse.drop(1)  #array of subjects with ORs in between
      }.merge(options))
  end

  class IMAPService
    attr_accessor :imap, :account

    def imap_server
      raise "not implemented"
    end

    def initialize(account)
      self.imap = Net::IMAP.new(imap_server, 993, usessl = true, certs = nil, verify = false)
      self.imap.authenticate('XOAUTH2', account.email, account.auth_token)
      self.imap.select('INBOX')
    rescue Net::IMAP::NoResponseError => e
      if e.message.include? "Invalid credentials"
        account.reset_access_token!
        account.refresh_token!
        raise "unable to refresh auth token" if account.auth_token.nil?
        retry
      end
    end

    def messages(options={})
      self.imap.search(options_to_imap_search(options)).map do |message_id|
        self.imap.fetch(message_id,'RFC822')[0].attr['RFC822']
      end
    end

    def emails(options={})
      messages(options).map{|msg| Mail.read_from_string msg}
    end

    def options_to_imap_search(options)
      options.map{|k,v| [k.upcase.to_s, v]}.flatten
    end
  end

  class GmailService < IMAPService

    def imap_server
      'imap.gmail.com'
    end
  end

  class YahooService < IMAPService

    def imap_server
      'imap.mail.yahoo.com'
    end
  end
end