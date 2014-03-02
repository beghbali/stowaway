class AddPublicIdToRequests < ActiveRecord::Migration
  def change
    add_column :requests, :public_id, :integer
  end
end
