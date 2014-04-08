module Payment
  def charge(amount, chargeable)
    ActiveRecord::Base.transaction do
      charge_amount, credit_amount = pay_from_credits!(amount, chargeable)
      charged = charge_credit_card!(charge_amount, chargeable) unless charge_amount == 0.00
      raise ActiveRecord::Rollback if (charged.amount + credit_amount) != amount
      [charged.try(:amount) || 0.00 , credit_amount, charged.try(:id)]
    end
  end

  def charge_credit_card!(amount, chargeable)
    Stripe::Charge.create(
      amount: amount,
      currency: "usd",
      customer: self.customer_id,
      description: chargeable.to_s(:charge)
    )
  rescue Exception
    raise ActiveRecord::Rollback
  end

  def pay_from_credits!(amount)
    used_credits = [amount, amount - self.credits].max
    self.credits -= used_credits
    [amount - used_credits, used_credits]
  end

end

