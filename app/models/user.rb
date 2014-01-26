class User < ActiveRecord::Base
  include PublicId

  has_public_id

  PROVIDERS = %w(facebook)
  SUPPORTED_EMAIL_PROVIDERS = %w(gmail yahoo other)

  validates :uid, uniqueness: true
  validates :provider, inclusion: { in: PROVIDERS }
  validates :email_provider, inclusion: { in: SUPPORTED_EMAIL_PROVIDERS }, :allow_blank => true

  before_save :create_stowaway_email, :if => :can_create_email?

  def update_facebook_attributes!(fb_attributes)
    self.update_attributes!(fb_attributes)
  end

  def create_stowaway_email(postfix='')
    proposed_email = [first_name, last_name, "pirate", rand(1..99), postfix].join.downcase

    if User.where("stowaway_email LIKE '#{proposed_email}@'").any?
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

end
