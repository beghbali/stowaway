class AddLastLatLngToRequests < ActiveRecord::Migration
  def change
    add_column :requests, :last_lat, :decimal, precision: 16, scale: 12
    add_column :requests, :last_lng, :decimal, precision: 16, scale: 12
  end
end
