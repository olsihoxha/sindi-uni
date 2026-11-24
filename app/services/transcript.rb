class Transcript
  def self.call(student, start_semester: nil, end_semester: nil)
    first = Semester.order(start_semester) if start_semester.present?
    last = Semester.order(end_semester) if end_semester.present?
    raise ArgumentError, "Start semester must be before or equal to end semester" if first && last && first > last
    enrollments = student.enrollments.includes(:grades, course: :assessments).joins(:course).order("courses.semester_order", "courses.code")
    enrollments = enrollments.where("courses.semester_order >= ?", first) if first
    enrollments = enrollments.where("courses.semester_order <= ?", last) if last
    { student: { id: student.id, name: student.full_name }, semesters: enrollments.group_by { |e| e.course.semester }.map do |semester, rows|
      { semester: semester, courses: rows.map do |enrollment|
        course = enrollment.course
        { code: course.code, name: course.name, **GradeSummary.call(enrollment), assessments: course.assessments.map do |item|
          { title: item.title, weight: item.weight.to_f, grade: enrollment.grades.find { |g| g.assessment_id == item.id }&.value }
        end }
      end }
    end }
  end
end
