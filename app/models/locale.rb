class Locale < ActiveRecord::Base
  RADIUS = 0.5
  scope :by_location, ->(location) { near(location, RADIUS, latitude: :lat, longitude: :lng) }

  def self.import(file)
    CSV.foreach(file.path, headers: true) do |row|
      locale = find_by_name(row['name']) || new
      locale.attributes = row.to_hash
      locale.save!
    end
  end
end
