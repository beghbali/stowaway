class AddStowawayEmailPasswordToUsers < ActiveRecord::Migration
  def change
    add_column :users, :stowaway_email_password, :string
  end
end
