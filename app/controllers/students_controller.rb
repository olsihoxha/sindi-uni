class StudentsController < ApplicationController
  before_action :require_instructor
  before_action :set_student, only: %i[show edit update destroy]
  def index
    @students = User.students.order(:surname, :name).includes(:enrollments)
  end
  def show
    @enrollments = @student.enrollments.includes(:grades, course: :assessments)
  end
  def new
    @student = User.new(role: "student")
  end
  def create
    @student = User.new(student_params.merge(role: "student"))
    if @student.save
      redirect_to student_path(@student), notice: "Student created."
    else
      render :new, status: :unprocessable_entity
    end
  end
  def edit; end
  def update
    if @student.update(student_params)
      redirect_to student_path(@student), notice: "Student updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end
  def destroy
    @student.destroy!
    redirect_to students_path, notice: "Student and their enrollments and grades deleted.", status: :see_other
  end

  private
  def set_student = @student = User.students.find(params[:id])
  def student_params
    attributes = params.require(:user).permit(:name, :surname, :email, :password, :password_confirmation).to_h
    attributes.except!("password", "password_confirmation") if action_name == "update" && attributes["password"].blank?
    attributes
  end
end
