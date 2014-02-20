class IncreasePercisionOnLatLng < ActiveRecord::Migration
  def change
    change_column :requests, :pickup_lat, :decimal, precision: 16, scale: 12
    change_column :requests, :pickup_lng, :decimal, precision: 16, scale: 12
    change_column :requests, :dropoff_lat, :decimal, precision: 16, scale: 12
    change_column :requests, :dropoff_lng, :decimal, precision: 16, scale: 12
  end
end
