class AddDeviceTypeAndTokenToRequests < ActiveRecord::Migration
  def change
    add_column :requests, :device_type, :string
    add_column :requests, :device_token, :string
  end
end
