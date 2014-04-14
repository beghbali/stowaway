class AddExpirationToCouponAndCouponToUsers < ActiveRecord::Migration
  def change
    add_column :coupons, :expires_at, :timestamp
    add_column :users, :coupon_code, :string
    PercentCoupon.create!(code: 'LONERIDER', discount: 0.50, expires_at: nil)
  end
end
