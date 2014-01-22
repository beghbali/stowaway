class User < ActiveRecord::Base
  PROVIDERS = %w(facebook)
  SUPPORTED_EMAIL_PROVIDERS = %w(gmail yahoo other)

  validates :uid, uniqueness: true
  validates :provider, inclusion: { in: PROVIDERS }
  validates :email_provider, inclusion: { in: SUPPORTED_EMAIL_PROVIDERS }

  before_create :create_stowaway_email

  def update_facebook_attributes!(fb_attributes)
    self.update_attributes!(fb_attributes)
  end

  def create_stowaway_email
    self.stowaway_email = Mailboto::Email.new.create([first_name, last_name, "pirate", rand(1..99)].join.downcase)
  end
end
