require "test_helper"

class ApiTest < ActionDispatch::IntegrationTest
  setup { build_academic_data }

  def entry(value = 85, student = @student)
    { student_id: student.id, course_code: @course.code, semester: @course.semester, assessment_title: "Midterm", grade: value }
  end

  test "API requires credentials and never falls back to browser session" do
    get api_v1_students_path
    assert_response :unauthorized
    assert_equal "Valid HTTP Basic credentials required", response.parsed_body["error"]
    login_as
    get api_v1_students_path
    assert_response :unauthorized
    get api_v1_students_path, headers: { "Authorization" => ActionController::HttpAuthentication::Basic.encode_credentials(@instructor.email, "bad") }
    assert_response :unauthorized
  end

  test "instructor student API supports index create read update and delete" do
    headers = api_headers
    get api_v1_students_path, headers: headers
    assert_response :success
    assert_equal 2, response.parsed_body["students"].size
    assert_not_includes response.body, "password"
    post api_v1_students_path, headers: headers, as: :json, params: { student: { name: "New", surname: "Student", email: "new@test.com", password: "Password123", role: "instructor" } }
    assert_response :created
    student = response.parsed_body["student"]
    assert_equal "student", student["role"]
    get api_v1_student_path(student["id"]), headers: headers
    assert_response :success
    patch api_v1_student_path(student["id"]), headers: headers, as: :json, params: { student: { name: "Updated" } }
    assert_response :success
    assert_equal "Updated", response.parsed_body["student"]["name"]
    delete api_v1_student_path(student["id"]), headers: headers
    assert_response :no_content
    assert_not User.exists?(student["id"])
  end

  test "student API rejects invalid and duplicate input" do
    post api_v1_students_path, headers: api_headers, as: :json, params: { student: { name: "A", surname: "B", email: @instructor.email, password: "weak" } }
    assert_response :unprocessable_entity
    assert response.parsed_body["details"].any?
    post api_v1_students_path, headers: api_headers, as: :json, params: {}
    assert_response :unprocessable_entity
    get api_v1_student_path(@instructor), headers: api_headers
    assert_response :not_found
  end

  test "student cannot use any student management endpoint or grade submission" do
    headers = api_headers(@student)
    get api_v1_students_path, headers: headers
    assert_response :forbidden
    get api_v1_student_path(@student), headers: headers
    assert_response :forbidden
    post api_v1_students_path, headers: headers, as: :json, params: { student: { name: "Bad" } }
    assert_response :forbidden
    patch api_v1_student_path(@student), headers: headers, as: :json, params: { student: { role: "instructor" } }
    assert_response :forbidden
    delete api_v1_student_path(@other), headers: headers
    assert_response :forbidden
    post api_v1_grades_path, headers: headers, as: :json, params: { entries: [entry] }
    assert_response :forbidden
    assert_equal 0, Grade.count
  end

  test "transcript restricts students to themselves and groups courses by semester" do
    record_grades
    get api_v1_transcripts_path, headers: api_headers(@student), params: { student_id: @student.id }
    assert_response :success
    semester = response.parsed_body["semesters"].first
    assert_equal @course.semester, semester["semester"]
    assert_equal 80.5, semester["courses"].first["overall_grade"]
    assert_equal 3, semester["courses"].first["assessments"].size
    get api_v1_transcripts_path, headers: api_headers(@student), params: { student_id: @other.id }
    assert_response :forbidden
    get api_v1_transcripts_path, headers: api_headers, params: { student_id: @other.id }
    assert_response :success
  end

  test "transcript filters inclusive semester ranges chronologically" do
    previous = Course.create!(code: "CS111", name: "Earlier", semester: Semester.label(@course.semester_order - 1))
    previous.enrollments.create!(student: @student)
    get api_v1_transcripts_path, headers: api_headers, params: { student_id: @student.id, start_semester: @course.semester, end_semester: @course.semester }
    assert_response :success
    assert_equal [@course.semester], response.parsed_body["semesters"].map { |item| item["semester"] }
    get api_v1_transcripts_path, headers: api_headers, params: { student_id: @student.id, end_semester: previous.semester }
    assert_equal [previous.semester], response.parsed_body["semesters"].map { |item| item["semester"] }
    get api_v1_transcripts_path, headers: api_headers, params: { student_id: @student.id, start_semester: @course.semester, end_semester: previous.semester }
    assert_response :unprocessable_entity
    get api_v1_transcripts_path, headers: api_headers, params: { student_id: @student.id, start_semester: "nonsense" }
    assert_response :unprocessable_entity
    get api_v1_transcripts_path, headers: api_headers
    assert_response :unprocessable_entity
  end

  test "batch inserts and updates grades idempotently" do
    2.times do
      post api_v1_grades_path, headers: api_headers, as: :json, params: { entries: [entry] }
      assert_response :success
    end
    assert_equal 1, Grade.count
    post api_v1_grades_path, headers: api_headers, as: :json, params: { entries: [entry(95), entry(70, @other)] }
    assert_response :success
    assert_equal 2, response.parsed_body["count"]
    assert_equal 95, @enrollment.grades.first.value
  end

  test "batch rolls back earlier inserts and updates when a later entry is invalid" do
    @enrollment.grades.create!(assessment: @assessments.first, value: 60)
    assert_no_difference("Grade.count") do
      post api_v1_grades_path, headers: api_headers, as: :json, params: { entries: [entry(90), entry(121, @other)] }
    end
    assert_response :unprocessable_entity
    assert_match "Entry 2", response.parsed_body["error"]
    assert_equal 60, @enrollment.grades.first.value
  end

  test "batch rejects duplicates missing entries wrong courses and malformed input" do
    [[], "bad", ["bad"], [entry, entry], [entry.merge(course_code: "XX999")], [entry.except(:grade)], [entry.merge(student_id: @instructor.id)]].each do |entries|
      assert_no_difference("Grade.count") do
        post api_v1_grades_path, headers: api_headers, as: :json, params: { entries: entries }
      end
      assert_response :unprocessable_entity, entries.inspect
    end
  end
end
