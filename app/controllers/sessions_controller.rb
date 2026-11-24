class SessionsController < ApplicationController
  skip_before_action :require_login, only: %i[new create]
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { redirect_to login_path, alert: "Too many login attempts. Please wait three minutes." }

  def new
    redirect_to dashboard_path if current_user
  end

  def create
    user = User.find_by(email: params[:email].to_s.strip.downcase)
    if user&.authenticate(params[:password].to_s)
      reset_session
      session[:user_id] = user.id
      redirect_to dashboard_path, notice: "Welcome back, #{user.name}."
    else
      flash.now[:alert] = "Email or password is incorrect."
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    reset_session
    redirect_to welcome_path, notice: "You have been logged out.", status: :see_other
  end
end
