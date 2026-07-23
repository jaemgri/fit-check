class SessionsController < ApplicationController
  skip_before_action :require_login, only: [:new, :create]

  def new
  end

  def create
    user = User.find_by(email_address: params[:email_address].to_s.strip.downcase)

    if user&.authenticate(params[:password])
      session[:user_id] = user.id
      redirect_to root_path
    else
      redirect_to new_session_path, alert: "Invalid email or password."
    end
  end

  def destroy
    reset_session
    redirect_to new_session_path, notice: "Logged out."
  end
end
