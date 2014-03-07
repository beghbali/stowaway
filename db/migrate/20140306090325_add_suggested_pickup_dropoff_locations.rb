class AddSuggestedPickupDropoffLocations < ActiveRecord::Migration
  def change
    add_column :rides, :suggested_dropoff_address, :string
    add_column :rides, :suggested_dropoff_lat, :decimal, precision: 16, scale: 12
    add_column :rides, :suggested_dropoff_lng, :decimal, precision: 16, scale: 12
    add_column :rides, :suggested_pickup_address, :string
    add_column :rides, :suggested_pickup_lat, :decimal, precision: 16, scale: 12
    add_column :rides, :suggested_pickup_lng, :decimal, precision: 16, scale: 12
  end
end
