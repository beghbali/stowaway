module ReceiptParser
  class GmailParser

    attr_accessor :gmail

    def initialize(email, auth_token)
      gmail = Gmail.connect(:xoauth2, "email@domain.com", token: auth_token)
    end
  end
end

