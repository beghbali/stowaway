class CreateRoutes < ActiveRecord::Migration
  def change
    create_table :routes do |t|
      t.belongs_to :user
      t.integer :start_locale_id
      t.integer :end_locale_id
      t.integer :accuracy
      t.integer :count, default: 0
      t.string :added_by
      t.timestamp :last_notified_at
      t.timestamps
    end
  end
end
