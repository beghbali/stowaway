class Coupon < ActiveRecord::Base
  default_scope { where('expires_at IS NULL OR expires_at > ?', Time.now) }

  def apply(amount)
    amount - discount
  end
end
