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

  def generate_stowaway_email_address(postfix='')
    proposed_email = "#{[first_name, last_name, postfix].join('.').downcase}@getstowaway.com"

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
      Resque.enqueue(ParseEmailJob, self.public_id, { email: email.encoded })
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
end
