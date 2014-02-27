module Stowaway
  class Users < Grape::API
    version :v1
    format :json

    desc "handles user management"

    resources :users do
      helpers do
        def permitted_user_params
          [
            :first_name, :last_name, :email, :image_url, :token, :expires_at, :email_provider, :gender,
            :location, :verified, :profile_url, :gmail_access_token, :gmail_refresh_token, :stripe_token,
            :device_type, :device_token
          ]
        end

        def permitted_request_params
          [ :pickup_address, :dropoff_address, :pickup_lat, :pickup_lng, :dropoff_lat, :dropoff_lng ]
        end

        def new_user_params
          ActionController::Parameters.new(params.except(:route_info)).permit(:uid, :provider, user: permitted_user_params)
        end

        def user_params
          ActionController::Parameters.new(params.except(:route_info)).permit(permitted_user_params)
        end

        def request_params
          ActionController::Parameters.new(params.except(:route_info)).permit(request: permitted_request_params)
        end
      end

      desc "create a new user"
      params do
        requires :uid, type: String, desc: "user uid in the provider domain"
        requires :provider, type: String, desc: "authentication provider(e.g. facebook)", values: User::AUTHENTICATION_PROVIDERS
      end
      post do
        user = User.find_or_initialize_by(uid: new_user_params[:uid], provider: new_user_params[:provider])
        user.update_facebook_attributes!(new_user_params[:user]) unless user.nil?
        user
      end

      params do
        requires :id, type: Integer, desc: "stowaway user id"
      end
      put ':id' do
        user = User.find_by_public_id(params[:id])
        user.update(user_params) unless user.nil?
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
            user = User.find_by_public_id(params[:user_id])
            error!('User not found', 404) if user.nil?
            request = user.requests.create!(request_params[:request])
            request.ride.try(:reload)
          end

          desc "cancel a request"
          params do
            requires :id, type: Integer, desc: "request id"
          end

          delete do
            request = Request.find(params[:id])
            error!('Request not found', 404) if request.nil?
            request.destroy
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