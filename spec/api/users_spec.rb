require 'spec_helper'
include Requests::Mocks

describe Stowaway::Users do
  let(:facebook_user_attributes) do
    {
      provider: 'facebook',
      uid: SecureRandom.hex(10),
      user: FactoryGirl.attributes_for(:user).except(:uid, :provider)
    }
  end

  before { mock_external_requests }

  shared_examples_for 'user CRUD endpoints' do
    let(:prefix) { "/api/#{version}/users"}

    describe "POST /api/<version>/users" do
      let(:uid) { Random.rand(1000) }
      let(:attributes) { user_attributes.merge(provider: provider, uid: uid)}

      subject(:create_user) do
        post prefix, attributes
        response
      end

      subject(:user) { User.last }

      context 'with valid params' do
        it 'should return success' do
          expect(create_user.code.to_i).to eq(201)
        end

        it 'should create a user' do
          expect {
            create_user
          }.to change{ User.count }.by(1)
        end

        it 'should have updated the user fields' do
          create_user
          user.attribute_names.each do |attribute|
            if attributes.keys.include?(attribute)
              expect(user.send(attribute)).to eq(attributes[attribute])
            end
          end
        end

        context 'creating with same provider uid' do
          let(:uid) { 5 }

          it 'should be idempotent' do
            expect {
              create_user
              create_user
            }.to change{ User.count }.by(1)
          end
        end
      end

      context 'with invalid params' do
        let(:attributes) { user_attributes.except(:uid) }

        it 'should return error code' do
          expect(create_user.code.to_i).to eq(400)
        end

        it 'should not create a user' do
          expect {
            create_user
          }.to change{ User.count }.by(0)
        end
      end
    end
  end

  context 'v1' do
    let(:version) { 'v1' }
    version = 'v1'

    context 'with facebook auth' do
      let(:provider) { 'facebook' }
      let(:user_attributes) { facebook_user_attributes }

      it_behaves_like 'user CRUD endpoints'
    end
  end
end