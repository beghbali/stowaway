class AddScheduledRideFields < ActiveRecord::Migration
  def change
    add_column :requests, :requested_for, :datetime
    add_column :requests, :duration, :integer
    add_column :rides, :suggested_pickup_time, :datetime
  end
end
