require 'spec_helper'
include Requests::Mocks

describe Stowaway::Rides do
  before { mock_external_requests }

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
          if request.send(k).is_a?(BigDecimal)
            expect(request.send(k)).to be_within(0.00001).of(v.to_f)
          else
            expect(request.send(k)).to eq(v)
          end
        end
        expect(request.status).to eq('outstanding')
      end

      it 'should not create any rides' do
        expect(Ride.count).to eq(0)
      end
    end
  end

  shared_examples_for 'matching outstanding requests with similar routes' do
    let(:prefix) { "/api/#{version}/users/#{user.public_id}/requests" }

    describe "POST /api/<version>/users/<userid>/rides" do
      before do
        post prefix, request: request_data.except(:id).merge(existing_request.slice(:pickup_lat, :pickup_lng, :dropoff_lat, :dropoff_lng))
        allow(existing_request.user).to receive(:notify).and_return(true)
        allow(request.user).to receive(:notify).and_return(true)
      end

      subject(:request) { Request.last }
      subject(:ride) { Ride.last }

      it 'responds successfully' do
        expect(response.status.to_i).to eq(201)
      end

      it 'responds with a valid ride' do
        expect(json[:location_channel]).to be
        expect(json[:requests].count).to eq(2)
        expect(json[:requests].map{|r| r[:status]}.uniq).to eq(["matched"])
        json[:requests].each do |req|
          expect(req[:uid]).to be
        end
      end

      it 'creates a valid request' do
        expect(Request.count).to eq(2)
        expect(Request.pluck(:status).uniq.count).to eq(1)
        expect(Request.pluck(:status).uniq.first).to eq('matched')
      end

      it 'should create a ride' do
        expect(Ride.count).to eq(1)
        expect(ride.requests.count).to eq(2)
        expect(request.ride).to be
      end

      it 'should generate a location channel for the ride' do
        expect(ride.location_channel).to be
      end

      it 'should send a notification only to the first rider' do
        expect(existing_request.user).to receive(:notify)
      end
    end
  end

  context 'v1' do
    let(:version) { 'v1' }
    version = 'v1'

    let(:user) { FactoryGirl.create :user }
    let(:request_data) { FactoryGirl.attributes_for :request }

    it_behaves_like 'admin endpoints'
    it_behaves_like 'accepting a ride request'

    context 'with another rider with similar route' do
      let(:existing_request) { FactoryGirl.create :request, user: FactoryGirl.create(:user) }

      before do
        existing_request
      end

      it_behaves_like 'matching outstanding requests with similar routes'
    end
  end
end