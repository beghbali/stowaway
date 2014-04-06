class AddReceiptsToRequestsAndRides < ActiveRecord::Migration
  def change
    add_column :requests, :receipt_id, :integer
    add_column :rides, :receipt_id, :integer
  end
end
