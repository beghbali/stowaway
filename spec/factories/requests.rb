FactoryGirl.define do
  factory :request do
    pickup_address { "#{Faker::Address.street_address} #{Faker::Address.city}, #{Faker::Address.state} #{Faker::Address.zip_code}" }
    dropoff_address { "#{Faker::Address.street_address} #{Faker::Address.city}, #{Faker::Address.state} #{Faker::Address.zip_code}" }
    pickup_lat { 37.790774 + [0.0001, -0.0001].sample }
    pickup_lng { -122.467297 + [0.0001, -0.0001].sample }
    dropoff_lat { 37.793046  + [0.0001, -0.0001].sample }
    dropoff_lng { -122.404856 + [0.0001, -0.0001].sample }
    user

    trait :scheduled do
      requested_for { 30.minutes.from_now + (1..20).to_a.sample.minutes }
      duration { 15.minutes }
    end
  end
end
