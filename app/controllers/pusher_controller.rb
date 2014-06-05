class PusherController < ApplicationController
  protect_from_forgery :except => :auth # stop rails CSRF protection for this action

  def auth
    if current_user
      Rails.logger.info "AUTHENTICATING: #{params}"
      response = Pusher[params[:channel_name]].authenticate(params[:socket_id])
      render :json => response
    else
      render :text => "Forbidden", :status => '403'
    end
  end

  def current_user
    params[:user_id] && (params[:user_id] == ENV['PUSHER_SERVER_USER_ID'] || User.find_by_public_id(params[:user_id]))
  end
end