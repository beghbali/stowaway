class PusherController < ApplicationController
  protect_from_forgery :except => :auth # stop rails CSRF protection for this action

  def auth
    if current_user
      response = Pusher[params[:channel_name]].authenticate(params[:socket_id], {
        :user_id => current_user.id, # => required
        :user_info => { # => optional - for example
          :uid => current_user.uid,
        }
      })
      render :json => response
    else
      render :text => "Forbidden", :status => '403'
    end
  end

  def current_user
    params[:user_id] && User.find_by_public_id(params[:user_id])
  end
end