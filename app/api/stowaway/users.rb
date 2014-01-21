module Stowaway
  class Users < Grape::API
    version :v1
    format :json

    desc "handles user management"

    resource :users do
      helpers do
        def clean_params
          ActionController::Parameters.new(params)
        end
      end

      desc "create a new user"
      params do
        requires :uid, type: String, desc: "user uid in the provider domain"
        requires :provider, type: String, desc: "authentication provider(e.g. facebook)", values: User::PROVIDERS
      end
      post ':provider/:uid' do
        user = User.find_or_initialize_by(uid: clean_params[:uid], provider: clean_params[:provider])
        user.update_facebook_attributes!(clean_params[:user])
        user.id
      end

      params do
        requires :id, type: Integer, desc: "stowaway user id"
      end
      put ':id' do
        user = User.find(clean_params[:id])
        user.update_attributes(clean_params[:user])
      end

      namespace :admin do
        desc "the number of users"
        get 'count' do
          { count: User.count }
        end
      end
    end

  end
end