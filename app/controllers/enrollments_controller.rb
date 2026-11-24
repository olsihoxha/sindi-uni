class EnrollmentsController < ApplicationController
  before_action :require_instructor, except: :index
  before_action :set_course
  def index
    # Students may view the authenticated class roster, but never peers' grades.
    @enrollments = @course.enrollments.includes(:student).joins(:student).order("users.surname", "users.name")
    @available_students = User.students.where.not(id: @course.enrollments.select(:student_id)).order(:surname, :name) if current_user.instructor?
  end
  def create
    enrollment = @course.enrollments.new(params.require(:enrollment).permit(:student_id))
    if enrollment.save
      redirect_to course_enrollments_path(@course), notice: "Student enrolled."
    else
      redirect_to course_enrollments_path(@course), alert: enrollment.errors.full_messages.to_sentence
    end
  end
  def destroy
    @course.enrollments.find(params[:id]).destroy!
    redirect_to course_enrollments_path(@course), notice: "Enrollment and its grades removed.", status: :see_other
  end

  private
  def set_course = @course = Course.find(params[:course_id])
end
