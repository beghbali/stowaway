class CreatePayments < ActiveRecord::Migration
  def change
    create_table :payments do |t|
      t.decimal :amount, precision: 8, scale: 2, default: 0.00
      t.decimal :credits_used, precision: 8, scale: 2, default: 0.00
      t.decimal :credit_card_charge, precision: 8, scale: 2, default: 0.00
      t.decimal :fee, precision: 8, scale: 2, default: 0.00
      t.string :reference
      t.timestamps
    end
  end
end
