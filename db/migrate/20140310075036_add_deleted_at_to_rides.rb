class AddDeletedAtToRides < ActiveRecord::Migration
  def change
    add_column :rides, :deleted_at, :datetime
    add_index :rides, :deleted_at
  end
end
