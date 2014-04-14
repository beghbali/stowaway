class CreateCoupons < ActiveRecord::Migration
  def change
    create_table :coupons do |t|
      t.string :type
      t.string :code
      t.decimal :discount, precision: 8,  scale: 2
      t.timestamps
    end
  end
end
