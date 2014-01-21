class AddGmailTokenToUsers < ActiveRecord::Migration
  def change
    add_column :users, :gmail_access_token, :string
    add_column :users, :gmail_refresh_token, :string
  end
end
