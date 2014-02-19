FactoryGirl.define do
  factory :request do
    pickup_address "#{Faker::Address.street_address} #{Faker::Address.city}, #{Faker::Address.state} #{Faker::Address.zip_code}"
    dropoff_address "#{Faker::Address.street_address} #{Faker::Address.city}, #{Faker::Address.state} #{Faker::Address.zip_code}"
    pickup_lat Faker::Address.latitude
    pickup_lng Faker::Address.longitude
    dropoff_lat Faker::Address.latitude
    dropoff_lng Faker::Address.longitude
    device_type %w(ios android).sample
    device_token SecureRandom.hex(8)
  end
end
