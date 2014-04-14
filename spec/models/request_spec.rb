require 'spec_helper'
require 'stripe_mock'
include Requests::Mocks

describe Request do
  before do
    mock_external_requests
  end

  describe "coupons" do
    let(:request) { FactoryGirl.create :request, coupon_code: coupon.code }

    context 'with a basic amount coupon' do
      let(:coupon) { FactoryGirl.create :coupon }
      let(:price) { 10.00 }

      subject(:discounted_price) { request.coupon.apply(price) }

      it 'associates the coupon' do
        expect(request.coupon).to eq(coupon)
      end

      it 'applies the coupon correctly' do
        expect(discounted_price).to be_within(0.01).of(price - coupon.discount)
      end
    end

    context 'with a percent discount coupon' do
      let(:coupon) { FactoryGirl.create :percent_coupon }
      let(:price) { 10.00 }

      subject(:discounted_price) { request.coupon.apply(price) }

      it 'associates the coupon' do
        expect(request.coupon).to eq(coupon)
      end

      it 'applies the coupon correctly' do
        expect(discounted_price).to be_within(0.01).of(price * (1 - coupon.discount))
      end
    end
  end
end
