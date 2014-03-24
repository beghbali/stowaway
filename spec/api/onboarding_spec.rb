require 'spec_helper'
include Requests::Mocks

describe 'onboarding' do
  VERSIONS = %w(v1)

  let(:headers) { {'CONTENT_TYPE' => "application/json", 'ACCEPT' => 'application/json'} }

  before { mock_external_requests }

  shared_context 'existing user' do
    let(:existing_user_attributes) { new_user_attributes }
    let(:user) { FactoryGirl.create :user, existing_user_attributes }
    before do
      user
    end
  end

  shared_examples_for 'the onboarding process' do
    context 'screen 1 (FB Login)' do
      VERSIONS.each do |version|
        context 'using API version #{version}' do
          context 'with valid Facebook information create a user' do
            let(:data) do
             {
                provider: new_user_attributes[:provider],
                uid: new_user_attributes[:uid],
                user: new_user_attributes.except(:provider, :uid, :email, :email_provider)
              }
            end

            before do
              post "/api/#{version}/users", data.to_json, headers
            end

            subject(:user) { User.last }

            it 'should create a user' do
              expect(User.count).to eq(1)
            end

            it 'should return the newly created user id' do
              expect(response.status).to eq(201)
              expect(response.headers['Content-Type']).to eq('application/json')
              expect(json[:public_id]).to eq(user.public_id)
            end

            it 'should set all the fields correctly' do
              new_user_attributes.except(:email, :email_provider).each do |attribute, value|
                value = value.to_s if value.is_a?(ActiveSupport::TimeWithZone)
                expect(user.send(attribute)).to eq(value)
              end
            end

            it 'ensure a stowaway email address was created' do
              expect(user.stowaway_email).not_to be_nil
              expect(user.stowaway_email).to include('@getstowaway.com')
              expect(user.stowaway_email_password).to be_nil
            end
          end
        end
      end
    end

    context 'screen 2/2a (Uber Email Determination)' do
      VERSIONS.each do |version|
        context 'using API version #{version}' do
          include_context 'existing user' do
            let(:existing_user_attributes) { new_user_attributes.except(:email, :email_provider)}
          end
          context 'with a valid gmail/gmail hosted email address update a user' do
            let(:data) { new_user_attributes.slice(:email, :email_provider) }

            before do
              put "/api/#{version}/users/#{user.public_id}", data.to_json, headers
              user.reload
            end

            subject(:existing_user) { user }

            it 'should update the user' do
              expect(User.count).to eq(1)
              expect(response.status).to eq(200)
              expect(response.headers['Content-Type']).to eq('application/json')
            end

            it 'should set all the fields correctly' do
              expect(json[:email]).to eq(existing_user.email)
              expect(json[:email_provider]).to eq(existing_user.email_provider)
            end

            it 'ensure a stowaway email and password created' do
              expect(json[:stowaway_email]).to include(existing_user.stowaway_email)
              expect(existing_user.stowaway_email).to include(existing_user.first_name.downcase)
              expect(existing_user.stowaway_email).to include(existing_user.last_name.downcase)
              expect(existing_user.stowaway_email).to include('@getstowaway.com')
              expect(existing_user.stowaway_email_password).not_to be_nil
            end
          end
        end
      end
    end

    shared_examples_for 'updating certain fields on a user' do
      include_context 'existing user' do
        let(:existing_user_attributes) { new_user_attributes.except(*fields) }
      end
      let(:data) { new_user_attributes.slice(*fields) }
      let(:hidden_fields) { [:id, :token, :gmail_access_token, :gmail_refresh_token, :stowaway_email_password, :stripe_token] }

      before do
        put "/api/#{version}/users/#{user.public_id}", data.to_json, headers
        user.reload
      end

      it 'should update the user' do
        expect(User.count).to eq(1)
        expect(response.status).to eq(200)
        expect(response.headers['Content-Type']).to eq('application/json')
      end

      it 'should set all the fields correctly' do
        fields.each do |field|
          expect(user.send(field)).to eq(new_user_attributes[field])
          unless hidden_fields.include?(field.to_sym)
            expect(json[field]).to eq(user.send(field))
          end
        end
      end
    end

    context 'screen 3 (Gmail Oauth2)' do
      VERSIONS.each do |version|
        context 'using API version #{version}' do
          context 'with a valid gmail/gmail hosted email address update user oauth2 credentials' do
            it_behaves_like 'updating certain fields on a user' do
              let(:fields) { %w(gmail_access_token gmail_refresh_token)}
              let(:version) { version }
            end
          end
        end
      end
    end

    context 'screen 4 (CC Payment)' do
      VERSIONS.each do |version|
        context 'using API version #{version}' do
          context 'with valid credit card info, update user with stripe token' do
            it_behaves_like 'updating certain fields on a user' do
              let(:fields) { %w(stripe_token)}
              let(:version) { version }
            end
          end
        end
      end
    end
  end

  context 'as a new user' do
    let(:new_user_attributes) { FactoryGirl.attributes_for(:user).with_indifferent_access }
    it_behaves_like 'the onboarding process'
  end

end