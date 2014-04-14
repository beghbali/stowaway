class PercentCoupon < Coupon
  def apply(amount)
    [amount.to_f * (1.0 - discount), 0.0].max
  end
end