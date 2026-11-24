require "test_helper"

class WorkflowsTest < ActionDispatch::IntegrationTest
  setup { build_academic_data }

  test "public catalog has five semester filter rosters and statistics" do
    old = Course.create!(code: "CS999", name: "Old", semester: Semester.label(Semester.current - 5))
    get welcome_path
    assert_response :success
    assert_select "select#semester-filter option", count: 6
    assert_select "[data-statistics-url]", count: 1
    assert_select "a[href=?]", course_enrollments_path(@course)
    assert_select "body", text: /Not logged in/
    assert_select "body", text: /#{old.code}/, count: 0
    get statistics_course_path(@course, format: :json)
    assert_response :success
    assert_equal 0, response.parsed_body["count"]
    get statistics_course_path(old, format: :json)
    assert_response :not_found
  end

  test "protected pages redirect anonymous visitors" do
    [dashboard_path, students_path, courses_path, edit_profile_path, course_enrollments_path(@course), course_enrollment_grades_path(@course, @enrollment)].each do |path|
      get path
      assert_redirected_to login_path
    end
  end

  test "login error login routing and logout" do
    post login_path, params: { email: @instructor.email, password: "wrong" }
    assert_response :unprocessable_entity
    assert_select "[role=alert]", text: /incorrect/
    login_as
    get dashboard_path
    assert_select "h1", text: "Hello, Elira."
    delete logout_path
    assert_redirected_to welcome_path
    get dashboard_path
    assert_redirected_to login_path
  end

  test "student sees own grades and cannot read peers or mutate resources" do
    record_grades
    login_as(@student)
    get dashboard_path
    assert_response :success
    assert_select "body", text: /80.5/
    get course_enrollment_grades_path(@course, @enrollment)
    assert_response :success
    assert_select "input[type=submit]", count: 0
    get course_enrollment_grades_path(@course, @other_enrollment)
    assert_response :not_found
    get students_path
    assert_response :forbidden
    post course_enrollment_grades_path(@course, @enrollment), params: { grade: { assessment_id: @assessments.first.id, value: 120 } }
    assert_response :forbidden
    patch course_path(@course), params: { course: { name: "Hacked" } }
    assert_response :forbidden
    assert_equal "Web Applications", @course.reload.name
    get course_enrollments_path(@course)
    assert_response :success
    assert_select "body", text: /sara@test.com/, count: 0
    assert_select "a", text: "Manage grades", count: 0
  end

  test "instructor screens render including all forms" do
    record_grades
    login_as
    paths = [dashboard_path, students_path, new_student_path, student_path(@student), edit_student_path(@student), courses_path, new_course_path, course_path(@course), edit_course_path(@course), new_course_assessment_path(@course), edit_course_assessment_path(@course, @assessments.first), course_enrollments_path(@course), course_enrollment_grades_path(@course, @enrollment), new_course_enrollment_grade_path(@course, @enrollment), edit_course_enrollment_grade_path(@course, @enrollment, @enrollment.grades.first), edit_profile_path]
    paths.each do |path|
      get path
      assert_response :success, path
      assert_select "body", text: /Logged as instructor: Elira Dervishi/
    end
  end

  test "instructor CRUD flow for course assessments enrollment and grades" do
    login_as
    post courses_path, params: { course: { code: "CS555", name: "New course", semester: "Fall 2026" } }
    course = Course.find_by!(code: "CS555")
    assert_redirected_to course_path(course)
    patch course_path(course), params: { course: { name: "Updated course" } }
    assert_equal "Updated course", course.reload.name
    post course_assessments_path(course), params: { assessment: { title: "Exam", weight: 1 } }
    assessment = course.assessments.first!
    post course_enrollments_path(course), params: { enrollment: { student_id: @student.id } }
    enrollment = course.enrollments.first!
    post course_enrollment_grades_path(course, enrollment), params: { grade: { assessment_id: assessment.id, value: 99 } }
    grade = enrollment.grades.first!
    patch course_enrollment_grade_path(course, enrollment, grade), params: { grade: { value: 105 } }
    assert_equal 105, grade.reload.value
    delete course_enrollment_grade_path(course, enrollment, grade)
    assert_not Grade.exists?(grade.id)
    delete course_enrollment_path(course, enrollment)
    assert_not Enrollment.exists?(enrollment.id)
    patch course_assessment_path(course, assessment), params: { assessment: { title: "Final" } }
    assert_equal "Final", assessment.reload.title
    delete course_assessment_path(course, assessment)
    assert_not Assessment.exists?(assessment.id)
    delete course_path(course)
    assert_not Course.exists?(course.id)
  end

  test "instructor manages student and updates own profile" do
    login_as
    post students_path, params: { user: { name: "New", surname: "Student", email: "new@test.com", password: "Password123" } }
    student = User.find_by!(email: "new@test.com")
    patch student_path(student), params: { user: { name: "Updated", password: "", password_confirmation: "" } }
    assert_equal "Updated", student.reload.name
    assert student.authenticate("Password123")
    patch profile_path, params: { user: { name: "Changed", email: "changed@test.com", password: "NewPassword1", password_confirmation: "NewPassword1" } }
    assert_redirected_to edit_profile_path
    assert @instructor.reload.authenticate("NewPassword1")
    assert_equal "changed@test.com", @instructor.email
    delete student_path(student)
    assert_not User.exists?(student.id)
  end

  test "invalid submissions render understandable errors" do
    login_as
    post courses_path, params: { course: { code: "A", name: "", semester: "bad" } }
    assert_response :unprocessable_entity
    assert_select "[role=alert]", text: /Please check/
    post students_path, params: { user: { name: "", surname: "", email: "invalid", password: "short" } }
    assert_response :unprocessable_entity
    post course_enrollment_grades_path(@course, @enrollment), params: { grade: { assessment_id: @assessments.first.id, value: 121 } }
    assert_response :unprocessable_entity
  end
end
