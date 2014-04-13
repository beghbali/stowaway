class AddGmailAccessTokenExpiresAtToUsers < ActiveRecord::Migration
  def change
    add_column :users, :gmail_access_token_expires_at, :string
  end
end
