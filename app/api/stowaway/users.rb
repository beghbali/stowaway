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
          [ :pickup_address, :dropoff_address, :pickup_lat, :pickup_lng, :dropoff_lat, :dropoff_lng, :coupon_code, :requested_for, :duration, :device_type, :device_token ]
        end

        def new_user_params
          ActionController::Parameters.new(params.except(:route_info)).permit(:uid, :provider, user: permitted_user_params)
        end

        def user_params
          ActionController::Parameters.new(params.except(:route_info)).permit(permitted_user_params)
        end

        def new_request_params
          ActionController::Parameters.new(params.except(:route_info)).permit(request: permitted_request_params)
        end

        def request_params
          ActionController::Parameters.new(params.except(:route_info)).permit(permitted_request_params)
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
              optional :requested_for, type: DateTime, desc: "desired pickup time"
              optional :duration, type: Integer, desc: "how long to wait for"
            end
          end
          post do
            user = User.find_by_public_id(params[:user_id])
            error!('User not found', 404) if user.nil?
            ActiveRecord::Base.transaction do
              user.requests.active.each(&:deactivate!)
              Rails.logger.debug "DEACTIVATED"
              request = user.requests.create!(new_request_params[:request])
              request.update_routes
              Rails.logger.debug "REQUEST CREATED: #{request.inspect}"
              request
              error!('Service Unavailable', 503)
            end
          end

          desc "get request info"
          params do
            requires :id, type: Integer, desc: "request public id"
          end

          get ':id' do
            request = Request.find_by_public_id(params[:id])
            error!('Request not found', 404) if request.nil?
            request
          end

          desc "cancel a request"
          params do
            requires :id, type: Integer, desc: "request public id"
          end

          delete ':id' do
            request = Request.find_by_public_id(params[:id])
            error!('Request not found', 404) if request.nil?
            request.destroy
          end

          params do
            requires :id, type: Integer
            requires :user_id, type: Integer
            requires :type, type: String
          end
          get ':id/checkin/:type' do
            request = Request.find_by_public_id(params[:id])
            error!('Request not found', 404) if request.nil?
            params[:type] == 'checkedin' ?  request.checkin! : request.miss!
          end

          params do
            requires :id, type: Integer
            requires :user_id, type: Integer
            optional :coupon_code, type: String
          end
          put ':id' do
            request = Request.find_by_public_id(params[:id])
            request.update(request_params) unless request.nil?
            request
          end
        end

        resources :rides do
          desc "get ride info"
          params do
            requires :id, type: Integer, desc: "ride public id"
          end

          get ':id' do
            ride = Ride.find_by_public_id(params[:id])
            error!('Ride not found', 404) if ride.nil?
            ride
          end

          desc "finalize a ride"
          params do
            requires :id, type: Integer, desc: "ride public id"
          end

          put ':id/finalize' do
            ride = Ride.find_by_public_id(params[:id])
            error!('Ride not found', 404) if ride.nil?
            ride.finalize unless ride.finalized?
            ride.reload
          end

          desc "checkin a user into the ride"
          params do
            requires :id, type: Integer, desc: "ride public id"
            requires :user_id, type: Integer, desc: "user public id"
          end

          put ':id/checkin' do
            ride = Ride.find_by_public_id(params[:id])
            error!('Ride not found', 404) if ride.nil?
            user = User.find_by_public_id(params[:user_id])
            error!('User not found', 404) if user.nil?
            ride.start_checkin if user.captain_of?(ride)
            ride.reload
          end
        end
      end
    end

  end
end