class MoveDeviceTokenTypeToUsers < ActiveRecord::Migration
  def change
    remove_column :requests, :device_type, :string
    remove_column :requests, :device_token, :string

    add_column :users, :device_type, :string
    add_column :users, :device_token, :string
  end
end
