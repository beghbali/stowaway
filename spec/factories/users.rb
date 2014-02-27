FactoryGirl.define do
  factory :user do
    first_name Faker::Name.first_name
    last_name  Faker::Name.last_name
    provider  'facebook'
    uid       SecureRandom.hex(10)
    email     Faker::Internet.email
    image_url Faker::Internet.url
    token     SecureRandom.hex(14)
    expires_at 3.days.from_now
    email_provider ['gmail'].sample
    gender ['female', 'male'].sample
    location "#{Faker::Address.street_address} #{Faker::Address.city}, #{Faker::Address.state} #{Faker::Address.zip_code}"
    verified [true, false].sample
    profile_url Faker::Internet.url
    gmail_access_token  SecureRandom.base64(32)
    gmail_refresh_token  SecureRandom.base64(32)
    stripe_token SecureRandom.base64(32)
    device_type %w(ios android).sample
    device_token SecureRandom.hex(8)
  end
end
