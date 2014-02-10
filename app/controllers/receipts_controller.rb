class ReceiptsController < ApplicationController
  def index
    @user = User.find_by_public_id(params[:user_id])
  end
end