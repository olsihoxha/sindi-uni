class DashboardController < ApplicationController
  def index
    if current_user.instructor?
      @courses = Course.includes(:assessments, :enrollments).order(semester_order: :desc, code: :asc)
      @student_count = User.students.count
      @grade_count = Grade.count
      render :instructor
    else
      @enrollments = current_user.enrollments.includes(:grades, course: :assessments).joins(:course).order("courses.semester_order DESC", "courses.code")
      render :student
    end
  end
end
