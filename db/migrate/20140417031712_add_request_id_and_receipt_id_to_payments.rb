class AddRequestIdAndReceiptIdToPayments < ActiveRecord::Migration
  def change
    add_column :payments, :request_id, :integer
    add_column :receipts, :payment_id, :integer
  end
end
