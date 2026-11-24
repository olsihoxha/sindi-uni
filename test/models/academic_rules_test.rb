require "test_helper"

class AcademicRulesTest < ActiveSupport::TestCase
  setup { build_academic_data }

  test "weighted example from the brief equals 80.5" do
    record_grades
    summary = GradeSummary.call(@enrollment)
    assert_equal 80.5, summary[:overall_grade]
    assert summary[:complete]
  end

  test "ungraded assessments produce an incomplete result not a final zero" do
    @enrollment.grades.create!(assessment: @assessments.first, value: 80)
    summary = GradeSummary.call(@enrollment)
    assert_nil summary[:overall_grade]
    assert_equal 20.0, summary[:earned_points]
    assert_equal 1, summary[:graded_count]
  end

  test "zero and extra credit grades are valid and affect weighted result" do
    record_grades(@enrollment, [0, 120, 120])
    assert_equal 90.0, GradeSummary.call(@enrollment)[:overall_grade]
  end

  test "grade boundaries reject fractional blank and out of range input" do
    [-1, 121, 85.5, "85.5", nil, "not a grade"].each do |value|
      grade = @enrollment.grades.new(assessment: @assessments.first, value: value)
      assert_not grade.valid?, "Expected #{value.inspect} to be invalid"
    end
  end

  test "grade must match enrolled course and be unique" do
    other_course = Course.create!(code: "CS102", name: "Other", semester: "Fall 2026")
    foreign_assessment = other_course.assessments.create!(title: "Exam", weight: 1)
    assert_not @enrollment.grades.new(assessment: foreign_assessment, value: 50).valid?
    @enrollment.grades.create!(assessment: @assessments.first, value: 50)
    assert_not @enrollment.grades.new(assessment: @assessments.first, value: 60).valid?
  end

  test "assessment plan cannot exceed 100 percent or drift after grading" do
    assert_not @course.assessments.new(title: "Extra", weight: 0.1).valid?
    record_grades
    assert_not @assessments.first.update(weight: 0.2)
    assert_not @assessments.last.destroy
  end

  test "assessment validation and draft grade prohibition" do
    @assessments.last.destroy!
    assert_not @enrollment.grades.new(assessment: @assessments.first, value: 80).valid?
    assert_not @course.assessments.new(title: "Midterm", weight: 0.1).valid?
    [-0.1, 1.1, nil, "bad"].each { |weight| assert_not @course.assessments.new(title: "Test", weight: weight).valid? }
    assert_not @course.assessments.new(title: "x" * 31, weight: 0.1).valid?
    assert_not @course.assessments.new(title: "", weight: 0.1).valid?
  end

  test "user names email and passwords follow coursework validations" do
    @student.assign_attributes(name: "a" * 31)
    assert_not @student.valid?
    @student.assign_attributes(name: "a" * 26, surname: "b" * 25)
    assert_not @student.valid?
    @student.assign_attributes(name: "Sindi", surname: "Kola", email: "invalid")
    assert_not @student.valid?
    @student.email = "TEACHER@test.com"
    assert_not @student.valid?
    @student.email = "valid@test.com"
    ["short", "lowercase123", "UPPERCASE123", "NoDigitsHere"].each do |password|
      @student.password = password
      assert_not @student.valid?
    end
    @student.password = "ValidPass1"
    assert @student.valid?
    assert_not User.new(name: "A", surname: "B", email: "missing@test.com").valid?
  end

  test "course validates lengths presence uniqueness and semester" do
    [{ code: "AB" }, { code: "ABCDEFG" }, { name: "n" * 51 }, { name: "" }, { semester: "Spring 2026" }, { semester: "nonsense" }, { catalog_data: "x" * 501 }].each do |attributes|
      course = Course.new(code: "CS111", name: "Course", semester: "Fall 2026", **attributes)
      assert_not course.valid?, attributes.inspect
    end
    assert_not Course.new(code: "cs403", name: "Course", semester: "Fall 2026").valid?
  end

  test "only students enroll and cannot enroll twice" do
    assert_not @course.enrollments.new(student: @instructor).valid?
    assert_not @course.enrollments.new(student: @student).valid?
  end

  test "statistics use completed overall grades and population deviation" do
    assert_equal 0, CourseStatistics.call(@course)[:count]
    record_grades
    record_grades(@other_enrollment, [90, 80, 100])
    stats = CourseStatistics.call(@course)
    assert_equal 2, stats[:count]
    assert_equal 80.5, stats[:min]
    assert_equal 90.5, stats[:max]
    assert_equal 85.5, stats[:mean]
    assert_equal 5.0, stats[:standard_deviation]
  end

  test "semester ordering crosses years and returns five terms" do
    assert_equal ["Spr 2026", "Fall 2025", "Sum 2025", "Spr 2025", "Fall 2024"], Semester.recent(Date.new(2026, 1, 10))
    assert_operator Semester.order("Fall 2025"), :<, Semester.order("Spr 2026")
    assert_raises(ArgumentError) { Semester.order("Winter 2026") }
  end

  test "course and student deletion clean up dependent records" do
    record_grades
    assert_difference("Grade.count", -3) { @student.destroy! }
    record_grades(@other_enrollment)
    assert_difference("Grade.count", -3) { @course.destroy! }
    assert_equal 0, Assessment.count
    assert_equal 0, Enrollment.count
  end
end
