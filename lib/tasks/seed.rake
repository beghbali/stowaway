namespace :seed do
  task requests: :environment do
    require 'factory_girl'
    require 'faker'
    Dir.glob("./spec/factories/*.rb").each {|f| require(f) }

    5.times do
      FactoryGirl.create(:request, pickup_lat: slat, pickup_lng: slng, dropoff_lat: dlat, dropoff_lng: dlng, user: FactoryGirl.create(:user, device_token: nil, device_type: nil))
    end
  end

  def slat
    37.7264107 + rand/rand(100000)
  end

  def slng
    -122.4062718 + rand/rand(100000)
  end

  def dlat
    37.786873 + rand/rand(100000)
  end

  def dlng
    -122.391938 + rand/rand(100000)
  end
end
