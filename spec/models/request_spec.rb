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

      subject(:discounted_price) { request.coupon.apply(price).round(2) }

      it 'associates the coupon' do
        expect(request.coupon).to eq(coupon)
      end

      it 'applies the coupon correctly' do
        expect(discounted_price).to eq(price * (1 - coupon.discount))
      end

      context 'with a user who has the coupon' do
        let(:user) { FactoryGirl.create :user, coupon_code: coupon.code }
        let(:request) { FactoryGirl.create :request, user: user }

        before do
          FactoryGirl.create :coupon, :lone_rider
        end

        it 'should associate the coupon with the user' do
          expect(user.coupon).to eq(coupon)
        end

        it 'should create new requests with the given coupon' do
          expect(request.coupon).to eq(user.coupon)
        end

        it 'should update the coupon with a new one if added to the request' do
          request.update_attributes(coupon_code: 'LONERIDER')
          expect(request.coupon.code).to eq('LONERIDER')
        end
      end

      context 'with an expired coupon' do
        before do
          coupon.expires_at = 2.minutes.from_now
          coupon.save
          Timecop.travel(5.minutes.from_now)
        end

        it 'should not apply the discount' do
          expect(request.coupon).to be_nil
        end
      end
    end
  end
end
