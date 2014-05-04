class ConvertRequestedForToTimestamp < ActiveRecord::Migration
  def change
    change_column :requests, :requested_for, :timestamp
  end
end
