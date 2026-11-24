class ApplicationController < ActionController::Base
  before_action :require_login
  helper_method :current_user
  rescue_from ActiveRecord::RecordNotFound, with: :not_found
  rescue_from ActionController::ParameterMissing do
    render "shared/error", status: :bad_request, locals: { title: "Missing information", message: "Please complete all required fields and try again." }
  end

  private

  def current_user
    @current_user ||= User.find_by(id: session[:user_id]) if session[:user_id]
  end

  def require_login
    redirect_to login_path, alert: "Please log in to continue." unless current_user
  end

  def require_instructor
    render "shared/error", status: :forbidden, locals: { title: "Instructor access required", message: "This action is available to instructors only." } unless current_user&.instructor?
  end

  def not_found
    respond_to do |format|
      format.html { render "shared/error", status: :not_found, locals: { title: "Page not found", message: "This record does not exist or is not available to your account." } }
      format.json { render json: { error: "Record not found" }, status: :not_found }
    end
  end
end
