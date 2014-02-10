class CreateRequests < ActiveRecord::Migration
  def change
    create_table :requests do |t|
      t.references :user
      t.string :status, default: 'outstanding'
      t.string :pickup_address
      t.string :dropoff_address
      t.decimal :pickup_lat, precision: 10, scale: 6
      t.decimal :pickup_lng, precision: 10, scale: 6
      t.decimal :dropoff_lat, precision: 10, scale: 6
      t.decimal :dropoff_lng, precision: 10, scale: 6

      t.timestamps
    end
  end
end
