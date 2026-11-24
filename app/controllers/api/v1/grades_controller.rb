module Api
  module V1
    class GradesController < BaseController
      before_action :require_instructor
      def create
        raw = params.require(:entries)
        entries = raw.is_a?(Array) ? raw.map { |entry| entry.is_a?(ActionController::Parameters) ? entry.permit(:student_id, :course_code, :semester, :assessment_title, :grade).to_h : entry } : raw
        grades = SubmitGrades.call(entries)
        render json: { count: grades.size, grades: grades.map { |grade| { id: grade.id, enrollment_id: grade.enrollment_id, assessment_id: grade.assessment_id, grade: grade.value } } }
      end
    end
  end
end
