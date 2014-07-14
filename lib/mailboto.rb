module Mailboto

  class Email
    include HTTParty
    NONCE = '821222a91eb75f136ea40899'
    base_uri 'https://getstowaway.com/createInbox.php'

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

  class SignupPreference
    include HTTParty
    NONCE = '821222Aq3erdfgnqQFEJD1223'
    base_uri 'https://getstowaway.com/getter.php'

    attr_accessor :home, :work, :credit

    def initialize(user)
      response = self.class.get("?" + URI.encode(getter_params(user)), options: { headers: { 'ContentType' => 'application/json' } } )
      json = JSON.parse(response)
      self.home = json['home']
      self.work = json['work']
      self.credit = json['credit']
    end

    private
    def getter_params(user)
      {
        email: user.email,
        nonce: NONCE
      }.to_param
    end
  end
end