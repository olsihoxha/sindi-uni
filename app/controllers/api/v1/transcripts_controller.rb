module Api
  module V1
    class TranscriptsController < BaseController
      def show
        id = params.require(:student_id).to_s
        unless @current_user.instructor? || id == @current_user.id.to_s
          return render json: { error: "You may only read your own transcript" }, status: :forbidden
        end
        student = User.students.find(id)
        render json: Transcript.call(student, start_semester: params[:start_semester], end_semester: params[:end_semester])
      end
    end
  end
end
