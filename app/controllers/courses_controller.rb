class CoursesController < ApplicationController
  skip_before_action :require_login, only: :statistics
  before_action :require_instructor, except: %i[show statistics]
  before_action :set_course, only: %i[show edit update destroy statistics]
  def index
    @courses = Course.includes(:enrollments, :assessments).order(semester_order: :desc, code: :asc)
  end
  def show
    raise ActiveRecord::RecordNotFound unless current_user.instructor? || @course.enrollments.exists?(student: current_user)
  end
  def new
    @course = Course.new(semester: Semester.recent.first)
  end
  def create
    @course = Course.new(course_params)
    if @course.save
      redirect_to @course, notice: "Course created. Add assessment items to complete its grading plan."
    else
      render :new, status: :unprocessable_entity
    end
  end
  def edit; end
  def update
    if @course.update(course_params)
      redirect_to @course, notice: "Course updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end
  def destroy
    @course.destroy!
    redirect_to courses_path, notice: "Course and its enrollments, assessments and grades deleted.", status: :see_other
  end
  def statistics
    raise ActiveRecord::RecordNotFound unless Course.recent.exists?(@course.id)
    @statistics = CourseStatistics.call(@course)
    respond_to do |format|
      format.json { render json: @statistics }
      format.html
    end
  end

  private
  def set_course = @course = Course.find(params[:id])
  def course_params = params.require(:course).permit(:code, :name, :semester, :catalog_data)
end
