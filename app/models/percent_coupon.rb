class PercentCoupon < Coupon
  def apply(amount)
    [amount.to_f * (1.00 - discount), 0.00].max
  end
end