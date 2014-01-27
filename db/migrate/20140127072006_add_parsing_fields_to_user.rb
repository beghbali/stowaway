class AddParsingFieldsToUser < ActiveRecord::Migration
  def change
    add_column :users, :last_processed_email_sent_at, :datetime
  end
end
