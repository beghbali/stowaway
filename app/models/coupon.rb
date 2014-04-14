class Coupon < ActiveRecord::Base
  def apply(amount)
    [amount.to_f - discount, 0.0].max
  end
end
