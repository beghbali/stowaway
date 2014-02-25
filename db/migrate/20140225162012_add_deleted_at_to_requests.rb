class AddDeletedAtToRequests < ActiveRecord::Migration
  def change
    add_column :requests, :deleted_at, :datetime
    add_index :requests, :deleted_at
  end
end
