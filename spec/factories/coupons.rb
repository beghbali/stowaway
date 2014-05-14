FactoryGirl.define do
  factory :coupon do
    code { SecureRandom.hex 10 }
    discount { BigDecimal.new(rand, 8).round(2) }

    trait :lone_rider do
      code 'LONERIDER'
    end

    factory :percent_coupon, parent: :coupon, class: 'PercentCoupon' do
      discount { BigDecimal.new(rand, 8).round(2) }
    end
  end
end
