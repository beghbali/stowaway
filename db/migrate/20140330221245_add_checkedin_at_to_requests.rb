class AddCheckedinAtToRequests < ActiveRecord::Migration
  def change
    add_column :requests, :checkedin_at, :timestamp
  end
end
