class AddPublicIdToRides < ActiveRecord::Migration
  def change
    add_column :rides, :public_id, :integer
  end
end
