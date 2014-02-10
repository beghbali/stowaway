module Stowaway
  class Users < Grape::API
    version :v1
    format :json

    desc "handles user management"

    resources :users do
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

      route_param :user_id do
        resources :requests do

          desc "request a ride/find crew"
          params do
            group :request do
              requires :pickup_address, type: String, desc: "street address of the desired pickup location"
              requires :dropoff_address, type: String, desc: "street address of the desired dropoff location"
              requires :pickup_lat, type: Float, desc: "geocoded latitude of the desired pickup location"
              requires :pickup_lng, type: Float, desc: "geocoded longitude of the desired pickup location"
              requires :dropoff_lat, type: Float, desc: "geocoded latitude of the desired dropoff location"
              requires :dropoff_lng, type: Float, desc: "geocoded longitude of the desired dropoff location"
            end
          end
          post do
            user = User.find(clean_params[:user_id])
            error!('User not found', 404) if user.nil?
            request = user.requests.create!(clean_params[:request])
            request
          end
        end
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