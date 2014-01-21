module Mailboto

  class Email
    include HTTParty

    base_uri 'http://stow.mailbsend.com/createInbox.php'

    def create(name)
      self.class.post("?username=#{name}")
    end
  end
end