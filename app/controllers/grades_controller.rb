class GradesController < ApplicationController
  before_action :require_instructor, except: :index
  before_action :set_context
  before_action :set_grade, only: %i[edit update destroy]
  def index
    @grades = @enrollment.grades.includes(:assessment)
    @summary = GradeSummary.call(@enrollment)
  end
  def new
    @grade = @enrollment.grades.new
  end
  def create
    @grade = @enrollment.grades.new(grade_params)
    saved = @course.with_lock { @grade.save }
    if saved
      redirect_to course_enrollment_grades_path(@course, @enrollment), notice: "Grade recorded."
    else
      render :new, status: :unprocessable_entity
    end
  end
  def edit; end
  def update
    saved = @course.with_lock { @grade.update(grade_params) }
    if saved
      redirect_to course_enrollment_grades_path(@course, @enrollment), notice: "Grade updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end
  def destroy
    @grade.destroy!
    redirect_to course_enrollment_grades_path(@course, @enrollment), notice: "Grade deleted.", status: :see_other
  end

  private
  def set_context
    @course = Course.find(params[:course_id])
    scope = current_user.instructor? ? @course.enrollments : @course.enrollments.where(student: current_user)
    @enrollment = scope.find(params[:enrollment_id])
  end
  def set_grade = @grade = @enrollment.grades.find(params[:id])
  def grade_params = params.require(:grade).permit(:assessment_id, :value)
end
