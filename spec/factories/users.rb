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
  end
end
