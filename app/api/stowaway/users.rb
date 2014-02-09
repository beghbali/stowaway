module Stowaway
  class Users < Grape::API
    version :v1
    format :json

    desc "handles user management"

    resource :users do
      helpers do
        def clean_params
          ActionController::Parameters.new(params).permit!
        end
      end

      desc "create a new user"
      params do
        requires :uid, type: String, desc: "user uid in the provider domain"
        requires :provider, type: String, desc: "authentication provider(e.g. facebook)", values: User::AUTHENTICATION_PROVIDERS
      end
      post do
        user = User.find_or_initialize_by(uid: params[:uid], provider: params[:provider])
        user.update_facebook_attributes!(clean_params[:user]) unless user.nil?
        user
      end

      params do
        requires :id, type: Integer, desc: "stowaway user id"
      end
      put ':id' do
        user = User.find_by_public_id(params[:id])
        user.update(clean_params[:user]) unless user.nil?
        user
      end

      params do
        requires :id, type: Integer, desc: "stowaway user id"
      end
      get ':id' do
        User.find_by_public_id(params[:id])
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