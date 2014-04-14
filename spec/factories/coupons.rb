FactoryGirl.define do
  factory :coupon do
    code { SecureRandom.hex 10 }
    discount { BigDecimal.new(rand, 8) }

    factory :percent_coupon, parent: :coupon, class: 'PercentCoupon' do
      discount { BigDecimal.new(rand, 8) }
    end
  end
end
