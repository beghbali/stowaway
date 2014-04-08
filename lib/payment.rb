module Payment
  def charge(amount, chargeable)
    Stripe::Charge.create(
      amount: amount,
      currency: "usd",
      customer: self.customer_id,
      description: chargeable.to_s(:charge)
    )
  end
end

