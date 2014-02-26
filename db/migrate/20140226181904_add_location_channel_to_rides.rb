class AddLocationChannelToRides < ActiveRecord::Migration
  def change
    add_column :rides, :location_channel, :string
  end
end
