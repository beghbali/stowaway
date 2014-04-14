class AddCouponCodeToRequest < ActiveRecord::Migration
  def change
    add_column :requests, :coupon_code, :string
  end
end
