class AddEmailFieldsToUser < ActiveRecord::Migration
  def change
    add_column :users, :email_provider, :string
    add_column :users, :gender, :string
    add_column :users, :location, :string
    add_column :users, :verified, :boolean
    add_column :users, :profile_url, :string
    add_column :users, :stowaway_email, :string
  end
end
