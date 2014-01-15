require 'spec_helper'

describe Stowaway::Users do
  shared_examples_for 'admin endpoints' do
    let(:prefix) { "/api/#{version}/users/admin" }

    describe "GET /api/<version>/admin/count" do
      before do
        FactoryGirl.create :user
        get [prefix, "count"].join("/")
      end

      it 'shows correct count' do
        expect(json['count']).to eq(1)
      end
    end
  end 
  
  context 'v1' do
    let(:version) { 'v1' }
    version = 'v1'

    it_behaves_like 'admin endpoints'
  end
end