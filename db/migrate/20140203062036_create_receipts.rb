class CreateReceipts < ActiveRecord::Migration
  def change
    create_table :receipts do |t|
      t.string :generated_by
      t.string :billed_to
      t.datetime :ride_requested_at
      t.string :pickup_location
      t.string :dropoff_location
      t.string :payment_card
      t.decimal  :total_amount, precision: 8, scale: 2
      t.decimal :base_amount, precision: 8, scale: 2
      t.decimal :distance_amount, precision: 8, scale: 2
      t.decimal :time_amount, precision: 8, scale: 2
      t.decimal :surge_amount, precision: 8, scale: 2
      t.float :surge_multiple, precision: 8, scale: 2
      t.decimal :other_amount, precision: 8, scale: 2
      t.string :other_description
      t.string :driver_name
      t.float :distance, precision: 8, scale: 2 #miles
      t.integer :duration #seconds
      t.float :average_speed, precision: 8, scale: 2
      t.string :map_url
      t.timestamps
    end
  end
end
