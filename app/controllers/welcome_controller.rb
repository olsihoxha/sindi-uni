class WelcomeController < ApplicationController
  skip_before_action :require_login
  def index
    @semesters = Semester.recent
    @courses = Course.recent.includes(:enrollments)
  end
end
