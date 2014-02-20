require 'spec_helper'

describe Stowaway::Rides do
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
  
  context 'v1' do
    let(:version) { 'v1' }
    version = 'v1'

    it_behaves_like 'admin endpoints'
  end
end