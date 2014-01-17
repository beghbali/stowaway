require 'spec_helper'

describe Stowaway::Users do
  let(:facebook_user_attributes) do
    {
      :provider => 'facebook',
      :uid => '1234567',
      :info => {
        :nickname => 'jbloggs',
        :email => 'joe@bloggs.com',
        :name => 'Joe Bloggs',
        :first_name => 'Joe',
        :last_name => 'Bloggs',
        :image => 'http://graph.facebook.com/1234567/picture?type=square',
        :urls => { :Facebook => 'http://www.facebook.com/jbloggs' },
        :location => 'Palo Alto, California',
        :verified => true
      },
      :credentials => {
        :token => 'ABCDEF...', # OAuth 2.0 access_token, which you may wish to store
        :expires_at => 1321747205, # when the access token expires (it always will)
        :expires => true # this will always be true
      },
      :extra => {
        :raw_info => {
          :id => '1234567',
          :name => 'Joe Bloggs',
          :first_name => 'Joe',
          :last_name => 'Bloggs',
          :link => 'http://www.facebook.com/jbloggs',
          :username => 'jbloggs',
          :location => { :id => '123456789', :name => 'Palo Alto, California' },
          :gender => 'male',
          :email => 'joe@bloggs.com',
          :timezone => -8,
          :locale => 'en_US',
          :verified => true,
          :updated_time => '2011-11-11T06:21:03+0000'
        }
      }
    }
  end

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

    it_behaves_like 'admin endpoints'

    context 'with facebook auth' do
      let(:provider) { 'facebook' }
      let(:user_attributes) { facebook_user_attributes }

      it_behaves_like 'user CRUD endpoints'
    end
  end
end