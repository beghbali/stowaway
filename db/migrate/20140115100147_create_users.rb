class CreateUsers < ActiveRecord::Migration
  def change
    create_table :users do |t|
      t.string :first_name
      t.string :last_name
      t.string :provider
      t.string :uid
      t.string :email
      t.string :image_url
      t.string :token
      t.datetime :expires_at

      t.timestamps
    end
  end
end
