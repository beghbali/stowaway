module Mailboto

  class Email
    include HTTParty
    NONCE = '821222a91eb75f136ea40899'
    base_uri 'http://stow.mailbsend.com/createInbox.php'

    def create(name)
      self.class.post("?username=#{name}&nonce=#{NONCE}")
    end
  end
end