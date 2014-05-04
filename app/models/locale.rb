class Locale < ActiveRecord::Base
  RADIUS = 0.5
  scope :by_location, ->(location) { near(location, RADIUS, latitude: :lat, longitude: :lng) }
end
