class Locale < ActiveRecord::Base
  RADIUS = 1.7
  scope :by_location, ->(location) { order_by_distance(*location) }

  geocoded_by :name, latitude: :lat, longitude: :lng

  def self.import(file)
    CSV.foreach(file.path, headers: true) do |row|
      locale = find_by_name(row['name']) || new
      locale.attributes = row.to_hash
      locale.save!
    end
  end

  def self.order_by_distance(latitude, longitude)
    #https://github.com/alexreisner/geocoder/blob/8c000fdf7ee7a8bac9b9bb17429e94d2b371f4da/lib/geocoder/stores/active_record.rb#L155
    distance = distance_sql(latitude, longitude, order: "distance")
    near([latitude, longitude], RADIUS, latitude: :lat, longitude: :lng, order: "(#{distance}) ASC")
  end
end
