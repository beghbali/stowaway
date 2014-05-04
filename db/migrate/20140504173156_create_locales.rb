class CreateLocales < ActiveRecord::Migration
  def change
    create_table :locales do |t|
      t.string :name
      t.decimal :lat, precision: 16, scale: 12
      t.decimal :lng, precision: 16, scale: 12
      t.integer :accuracy
      t.timestamps
    end
  end
end
