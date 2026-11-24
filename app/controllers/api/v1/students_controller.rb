module Api
  module V1
    class StudentsController < BaseController
      before_action :require_instructor
      before_action :set_student, only: %i[show update destroy]
      def index
        render json: { students: User.students.order(:id).map { |student| student_json(student) } }
      end
      def show
        render json: { student: student_json(@student) }
      end
      def create
        student = User.create!(student_params.merge(role: "student"))
        render json: { student: student_json(student) }, status: :created
      end
      def update
        @student.update!(student_params)
        render json: { student: student_json(@student) }
      end
      def destroy
        @student.destroy!
        head :no_content
      end

      private
      def set_student = @student = User.students.find(params[:id])
      def student_params
        attributes = params.require(:student).permit(:name, :surname, :email, :password, :password_confirmation).to_h
        attributes.except!("password", "password_confirmation") if action_name == "update" && attributes["password"].blank?
        attributes
      end
    end
  end
end
