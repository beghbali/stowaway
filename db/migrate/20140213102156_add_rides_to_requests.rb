class AddRidesToRequests < ActiveRecord::Migration
  def change
    add_column :requests, :ride_id, :integer
    add_column :requests, :designation, :string

    add_index :requests, :status
    add_index :requests, :designation
  end
end
