ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

class ActiveSupport::TestCase
  # A small suite runs sequentially so SQLite and transaction tests stay deterministic.
  def build_academic_data
    @instructor = User.create!(name: "Elira", surname: "Dervishi", email: "teacher@test.com", password: "Password123", role: "instructor")
    @student = User.create!(name: "Sindi", surname: "Kola", email: "sindi@test.com", password: "Password123")
    @other = User.create!(name: "Sara", surname: "Leka", email: "sara@test.com", password: "Password123")
    @course = Course.create!(code: "CS403", name: "Web Applications", semester: Semester.recent.first)
    @assessments = [["Midterm", "0.25"], ["Project", "0.35"], ["Final Exam", "0.40"]].map { |title, weight| @course.assessments.create!(title: title, weight: weight) }
    @enrollment = @course.enrollments.create!(student: @student)
    @other_enrollment = @course.enrollments.create!(student: @other)
  end

  def record_grades(enrollment = @enrollment, values = [80, 70, 90])
    @assessments.zip(values).each { |assessment, value| enrollment.grades.create!(assessment: assessment, value: value) }
  end

  def login_as(user = @instructor)
    post login_path, params: { email: user.email, password: "Password123" }
    assert_redirected_to dashboard_path
  end

  def api_headers(user = @instructor)
    { "Authorization" => ActionController::HttpAuthentication::Basic.encode_credentials(user.email, "Password123") }
  end
end
