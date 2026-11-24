module Api
  module V1
    class BaseController < ActionController::API
      include ActionController::HttpAuthentication::Basic::ControllerMethods
      before_action :authenticate
      rescue_from ActiveRecord::RecordNotFound do
        render json: { error: "Record not found" }, status: :not_found
      end
      rescue_from ActiveRecord::RecordInvalid do |exception|
        render json: { error: "Validation failed", details: exception.record.errors.full_messages }, status: :unprocessable_entity
      end
      rescue_from ActionController::ParameterMissing, ArgumentError do |exception|
        render json: { error: exception.message }, status: :unprocessable_entity
      end
      rescue_from ActiveRecord::RecordNotUnique do
        render json: { error: "This record already exists" }, status: :conflict
      end

      private
      def authenticate
        authenticate_with_http_basic do |email, password|
          user = User.find_by(email: email.strip.downcase)
          @current_user = user if user&.authenticate(password)
        end
        unless @current_user
          response.set_header("WWW-Authenticate", 'Basic realm="Gradebook"')
          render json: { error: "Valid HTTP Basic credentials required" }, status: :unauthorized
        end
      end
      def require_instructor
        render json: { error: "Instructor access required" }, status: :forbidden unless @current_user.instructor?
      end
      def student_json(student)
        student.as_json(only: %i[id name surname email role])
      end
    end
  end
end
