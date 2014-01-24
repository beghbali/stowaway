module Mailboto

  class Email
    include HTTParty
    NONCE = '821222a91eb75f136ea40899'
    base_uri 'http://stow.mailbsend.com/createInbox.php'

    def create(name, existing_email)
      response = self.class.post("?" + mailboto_params(name, existing_email), options: { headers: { 'ContentType' => 'application/json' } } )
      json = JSON.parse(response)
      [json['email'], json['password']]
    end

    private
    def mailboto_params(username, forward)
      {
        username: username,
        nonce: NONCE,
        forward: forward
      }.to_param
    end
  end
end