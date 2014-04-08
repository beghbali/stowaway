require 'spec_helper'
require 'stripe_mock'
include Requests::Mocks

describe Stowaway::Rides do
  before do
    Object.send(:remove_const, :APNS)
    APNS = double()
    mock_external_requests
  end

  after { unmock_external_requests }

  shared_examples_for 'admin endpoints' do
    let(:prefix) { "/api/#{version}/rides/admin" }

    describe "GET /api/<version>/admin/status" do
      before do
        get [prefix, "status"].join("/")
      end

      it 'shows correct status' do
        expect(response.status.to_i).to eq(200)
        expect(response.body).to include('Arrr')
      end
    end
  end

  shared_examples_for 'accepting a ride request' do
    let(:prefix) { "/api/#{version}/users/#{user.public_id}/requests" }

    describe "POST /api/<version>/users/<userid>/requests" do
      before do
        post prefix, request: request_data
      end

      subject(:request) { Request.last}

      it 'responds successfully' do
        expect(response.status.to_i).to eq(201)
      end

      it 'creates a valid request' do
        expect(Request.count).to eq(1)
        request_data.each do |k,v|
          expect_values_to_match(request.send(k), v)
        end
        expect(request.status).to eq('outstanding')
      end

      it 'should not create any rides' do
        expect(Ride.count).to eq(0)
      end
    end
  end

  shared_examples_for 'a finalized ride' do

    it 'designates a captain' do
      expect(ride.captain).not_to be_nil
      expect(ride.requests.captains.count).to eq(1)
    end

    it 'marks requests and fulfilled' do
      expect(ride.requests.pluck(:status).uniq).to eq(["fulfilled"])
    end

    it 'designates everyone else as stowaway' do
      expect(ride.stowaways.count).to eq(ride.requests.count - 1)
    end

    context 'when getting the ride info' do
      before do
        get "/api/#{version}/users/#{user.public_id}/rides/#{ride.public_id}"
      end

      it 'should include suggested drop off location' do
        expect(json[:suggested_dropoff_address]).not_to be_nil
        expect(json[:suggested_dropoff_lat]).not_to be_nil
        expect(json[:suggested_dropoff_lng]).not_to be_nil
      end

      it 'should include suggested pickup location' do
        expect(json[:suggested_pickup_address]).not_to be_nil
        expect(json[:suggested_pickup_lat]).not_to be_nil
        expect(json[:suggested_pickup_lng]).not_to be_nil
      end

      it 'should set the suggested pickup location to the location of the captain' do
        expect(json[:suggested_pickup_address]).to eq(ride.captain.pickup_address)
        expect_values_to_match(json[:suggested_pickup_lat], ride.captain.pickup_lat)
        expect_values_to_match(json[:suggested_pickup_lng], ride.captain.pickup_lng)
      end

      it 'should show fulfilled for all requests' do
        expect(json[:requests].map{|r| r[:status]}.uniq).to eq(['fulfilled'])
      end

      it 'should have designated the captain and stowaways correctly' do
        expect(json[:requests].select{|r| r[:designation] == 'stowaway'}.count).to eq(ride.requests.count - 1)
        expect(json[:requests].select{|r| r[:designation] == 'captain'}.count).to eq(1)
      end
    end

  end

  shared_examples_for 'matching outstanding requests with similar routes' do
    let(:prefix) { "/api/#{version}/users/#{user.public_id}/requests" }
    let(:expected_status) { "matched" }
    let(:cancellation_count) { 0 }
    let(:rematch_count) { 0 }

    before do
      expect(APNS).to receive(:send_notification).exactly(notification_count + cancellation_count + rematch_count).times
      post prefix, request: request_data.except(:id).merge(existing_request.slice(:pickup_lat, :pickup_lng, :dropoff_lat, :dropoff_lng))
    end

    subject(:request) { Request.last }
    subject(:ride) { Ride.last }

    it 'responds successfully' do
      expect(response.status.to_i).to eq(201)
    end

    it 'creates a valid request' do
      expect(Request.count).to eq(existing_requests.count + 1)
      expect(Request.pluck(:status).uniq.count).to eq(1)
      expect(Request.pluck(:status).uniq.first).to eq(expected_status)
    end

    it 'should create a ride' do
      expect(Ride.count).to eq(1)
      expect(ride.requests.count).to eq(existing_requests.count + 1)
      expect(request.ride).to be
    end

    it 'response includes the ride public id' do
      expect(json[:ride_public_id]).to eq(request.ride.public_id)
    end

    context 'cancelling the request' do
      include_context 'cancelling a request'
      let(:notification_count) { 0 }
      let(:cancellation_count) { existing_requests.count }
      let(:rematch_count) { existing_requests.count }

      it_behaves_like 'a cancelled request'
    end

    context 'cancellations' do
      let(:rematch_count) { existing_requests.count }

      include_context 'finalized ride'

      context 'everyone besides captain cancelling the ride' do
        let(:cancellation_count) { (1..existing_requests.count).reduce(:+) }

        include_context 'everyone besides captain cancelling a ride' do
          let(:requests) { ride.requests }
        end

        it_behaves_like 'a cancelled ride' do
          let(:requests) { ride.requests }
        end
      end

      context 'captain cancelling the ride' do
        let(:cancellation_count) { existing_requests.count }

        include_context 'captain cancelling a ride' do
          let(:requests) { ride.requests }
        end

        it_behaves_like 'a cancelled ride' do
          let(:requests) { ride.requests }
        end
      end
    end

    context 'when getting the ride info' do
      before do
        get "/api/#{version}/users/#{user.public_id}/rides/#{ride.public_id}"
      end

      it 'responds with a valid ride' do
        expect(json[:location_channel]).to be
        expect(json[:requests].count).to eq(existing_requests.count + 1)
        expect(json[:requests].map{|r| r[:status]}.uniq).to eq([expected_status])
        json[:requests].each do |req|
          expect(req[:uid]).to be
        end
      end

      it 'should generate a location channel for the ride' do
        expect(ride.location_channel).to be
      end

      it 'should have the status' do
        expect(json[:status]).to eq(ride.requests.pluck(:status).uniq.first)
      end
    end
  end

  shared_examples_for 'a cancelled ride' do
    it 'should soft delete ride' do
      expect(Ride.where(id: ride.id).count).to be(0)
      expect(Ride.unscoped.where(id: ride.id).count).to be(1)
    end

    it 'should reset other requests back to outstanding' do
      existing_requests.each do |request|
        expect(['matched', 'outstanding']).to include(request.status)
      end
    end

    it 'cancels the request' do
      expect( Request.deleted.where(ride_id: ride.id).first.status).to eq('cancelled')
    end
  end

  shared_examples_for 'a cancelled request' do
    let(:duplicate_request) { FactoryGirl.build :request, request.attributes.except('id', 'public_id')}

    it 'should mark the request as cancelled' do
      expect(request.reload.status).to eq('cancelled')
    end

    it 'should not have the request in match scopes' do
      expect(Request.same_route(duplicate_request)).not_to include(request)
    end
  end

  shared_context 'cancelling a request' do
    before do
      delete "/api/#{version}/users/#{request.user.public_id}/requests/#{request.public_id}"
    end
  end

  shared_context 'everyone besides captain cancelling a ride' do
    before do
      requests.stowaways.each do |request|
        delete "/api/#{version}/users/#{request.user.public_id}/requests/#{request.public_id}"
      end
    end
  end

  shared_context 'captain cancelling a ride' do
    before do
      delete "/api/#{version}/users/#{ride.captain.user.public_id}/requests/#{ride.captain.public_id}"
    end
  end

  shared_context 'finalized ride' do
    let(:notification_count) { 0 }

    before do
      ride.finalize
    end
  end

  context 'v1' do
    let(:version) { 'v1' }
    version = 'v1'

    let(:user) { FactoryGirl.create :user }
    let(:request_data) { FactoryGirl.attributes_for :request }
    let(:notification_count) { existing_requests.count }

    it_behaves_like 'admin endpoints'
    it_behaves_like 'accepting a ride request'

    context 'with another rider with similar route' do
      let(:existing_request) { FactoryGirl.create :request }
      let(:existing_requests) { [ existing_request ] }

      before do
        existing_requests
      end

      it_behaves_like 'matching outstanding requests with similar routes'

      context 'cancelling one of the requests' do
        let(:request) { FactoryGirl.create :request }
        let(:ride) { request.ride }
        before do
          ride
        end

        include_context 'cancelling a request' do
          prepend_before do
            expect(APNS).to receive(:send_notification).exactly(2).times
          end
        end
        it_behaves_like 'a cancelled ride'
      end

      context 'with a third rider joining existing ride' do
        let(:existing_requests) { FactoryGirl.create_list(:request, 2) }

        let(:existing_request) { existing_requests.first }

        it_behaves_like 'matching outstanding requests with similar routes' do

          context 'when each rider sends a finalize message' do
            before do
              expect(APNS).to receive(:send_notification).exactly(0).times
              ride.requests.each do |request|
                put  "/api/#{version}/users/#{user.public_id}/rides/#{ride.public_id}/finalize"
              end
              ride.reload
            end

            it_behaves_like 'a finalized ride'
          end
        end

        context 'with a fourth rider joining existing ride' do
          let(:existing_requests) { FactoryGirl.create_list(:request, 3) }

          it_behaves_like 'matching outstanding requests with similar routes' do
            let(:expected_status) { 'fulfilled' }

            it_behaves_like 'a finalized ride'
          end
        end
      end
    end
  end

  def expect_values_to_match(a, b)
    if a.is_a?(BigDecimal) || b.is_a?(BigDecimal)
      expect(a.to_f).to be_within(0.00001).of(b.to_f)
    else
      expect(a).to eq(b)
    end
  end
end