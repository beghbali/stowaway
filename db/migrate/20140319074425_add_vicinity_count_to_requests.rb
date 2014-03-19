class AddVicinityCountToRequests < ActiveRecord::Migration
  def change
    add_column :requests, :vicinity_count, :integer, default: 0
  end
end
