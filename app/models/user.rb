class User < ActiveRecord::Base
  include PublicId
  include Emails

  has_public_id
  has_many :receipts

  AUTHENTICATION_PROVIDERS = %w(facebook)
  SUPPORTED_EMAIL_PROVIDERS = %w(gmail yahoo other)

  validates :uid, uniqueness: true
  validates :provider, inclusion: { in: AUTHENTICATION_PROVIDERS }
  validates :email_provider, inclusion: { in: SUPPORTED_EMAIL_PROVIDERS }, allow_blank: true
  validates :gender, inclusion: { in: %w(male female) }, allow_blank: true

  before_save :create_stowaway_email, :if => :can_create_email?


  def update_facebook_attributes!(fb_attributes)
    self.update_attributes!(fb_attributes)
  end

  def create_stowaway_email(postfix='')
    proposed_email = [first_name, last_name, "pirate", postfix].join.downcase

    if User.exists?(stowaway_email: "#{proposed_email}@getstowaway.com")
      create_stowaway_email(rand(1..99).to_s)
    else
      self.stowaway_email, self.stowaway_email_password = Mailboto::Email.new.create(proposed_email, email)
    end
  end

  def can_create_email?
    !self.email.nil? && self.stowaway_email.nil?
  end

  def to_h
    self.attributes.except([:token, :gmail_access_token, :gmail_refresh_token, :stowaway_email_password])
  end

  def to_json
    to_h.to_json
  end

  def fetch_ride_receipts
    unprocessed_emails.each do |email|
      Resque.enqueue(ParseEmailJob, self.public_id, { email: email.encoded })
    end
  end

  def reconcile_ride_receipts
    fetch_ride_receipts
    #reconcile stowaway receipts
  end
end
