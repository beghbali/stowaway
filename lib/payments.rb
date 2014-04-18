module Payments
  def charge(amount, chargeable)
    ActiveRecord::Base.transaction do
      charge_amount, credit_amount = pay_from_credits!(amount)
      charged = charge_credit_card!(charge_amount, chargeable) unless charge_amount == 0.00
      charged_amount = BigDecimal.new((charged.try(:amount) || 0.00)/100, 8)
      raise ActiveRecord::Rollback if ( charged_amount + credit_amount) != amount
      [charged_amount, credit_amount, charged.try(:id)]
    end
  end

  def charge_credit_card!(amount, chargeable)
    Stripe::Charge.create(
      amount: (amount * 100).round,
      currency: "usd",
      customer: self.customer_id,
      description: chargeable.to_s(:charge)
    )
  rescue Exception
    raise ActiveRecord::Rollback
  end

  def pay_from_credits!(amount)
    remaining_credits = self.credits - amount
    used_credits = remaining_credits < 0.0 ? self.credits : self.credits - remaining_credits
    self.credits -= used_credits
    [amount - used_credits, used_credits]
  end

  def credit(amount)
    ActiveRecord::Base.transaction do
      self.credits += amount
      save
    end
  end
end

