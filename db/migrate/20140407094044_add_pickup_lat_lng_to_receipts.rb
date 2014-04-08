class AddPickupLatLngToReceipts < ActiveRecord::Migration
  def change
    add_column :receipts, :pickup_lat, :decimal, precision: 16, scale: 12
    add_column :receipts, :pickup_lng, :decimal, precision: 16, scale: 12
  end
end
