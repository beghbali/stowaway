class User < ActiveRecord::Base
  include Notify::Notifiable
  include PublicId
  include Emails

  has_public_id
  has_many :receipts

  AUTHENTICATION_PROVIDERS = %w(facebook)
  SUPPORTED_EMAIL_PROVIDERS = %w(gmail yahoo other)
  DEVICE_TYPES = %w(ios android)

  has_many :requests
  has_many :rides, through: :requests
  belongs_to :coupon, foreign_key: :coupon_code, primary_key: :code

  validates :uid, uniqueness: true
  validates :provider, inclusion: { in: AUTHENTICATION_PROVIDERS }
  validates :email_provider, inclusion: { in: SUPPORTED_EMAIL_PROVIDERS }, allow_blank: true
  validates :gender, inclusion: { in: %w(male female) }, allow_blank: true
  validates :device_type, inclusion: { in: DEVICE_TYPES }, allow_blank: true

  before_create :generate_stowaway_email_address
  before_save :create_stowaway_email, if: :can_create_email?
  before_save :link_payment_card, if: :stripe_token_changed?

  def update_facebook_attributes!(fb_attributes)
    self.update_attributes!(fb_attributes)
  end

  def generate_stowaway_email_address(postfix=nil)
    proposed_email = "#{[first_name, last_name, postfix].compact.join('.').downcase}@getstowaway.com"

    if User.exists?(stowaway_email: proposed_email)
      proposed_email = generate_stowaway_email_address(rand(1..99).to_s)
    end
    self.stowaway_email = proposed_email
  end

  def create_stowaway_email(postfix='')
    generate_stowaway_email_address if self.stowaway_email.nil?
    self.stowaway_email, self.stowaway_email_password = Mailboto::Email.new.create(self.stowaway_email.split('@').first, email)
  end

  def can_create_email?
    self.email_changed? && self.email_was.nil?
  end

  def as_json(options={})
    super(options.merge(except: [:id, :token, :gmail_access_token, :gmail_refresh_token, :stowaway_email_password, :stripe_token]))
  end

  def fetch_ride_receipts
    unprocessed_emails.each do |email|
      ParseEmailJob.perform self.public_id, { email: email.encoded }
      # Resque.enqueue(ParseEmailJob, self.public_id, { email: email.encoded })
    end
  end

  def ride
    self.requests.outstanding.last.ride
  end

  def request_for(ride)
    self.requests.joins(:ride).where(rides: {id: ride.id}).last
  end

  def captain_of?(ride)
    self.request_for(ride).try(:captain?) || false
  end

  def link_payment_card
    return if self.stripe_token.blank?

    customer = Stripe::Customer.create(
      card: self.stripe_token,
      description: "#{self.email}"
    )
    self.customer_id = customer.id
  end

  def auth_token
    self.send("#{self.email_provider}_access_token")
  end

  def auth_token=(value)
    self.send("#{self.email_provider}_access_token=", value)
  end

  def refresh_token
    self.send("#{self.email_provider}_refresh_token")
  end

  def refresh_token=(value)
    self.send("#{self.email_provider}_refresh_token=", value)
  end

  def auth_token_expires_at
    self.send("#{self.email_provider}_access_token_expires_at")
  end

  def auth_token_expires_at=(value)
    self.send("#{self.email_provider}_access_token_expires_at=", value)
  end

  def reset_access_token!
    self.auth_token = nil
    save
  end

  def refresh_token!
    response = HTTParty.post(token_request_url, refresh_token_request)

    if response.code == 200
      self.auth_token = response.parsed_response['access_token']
      self.auth_token_expires_at = DateTime.now + response.parsed_response['expires_in'].seconds
      save
    else
      false
    end
  end

  def refresh_token_request
    {
      body: {
        client_id:     ENV['GMAIL_CLIENT_ID'],
        client_secret: ENV['GMAIL_CLIENT_SECRET'],
        refresh_token: refresh_token,
        grant_type:    'refresh_token'
      },
      headers: {
        'Content-Type' => 'application/x-www-form-urlencoded'
      }
    }
  end

  def token_request_url
    self.send("#{self.email_provider}_token_request_url")
  end

  def gmail_token_request_url
    'https://accounts.google.com/o/oauth2/token'
  end
end
