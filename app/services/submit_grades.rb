# A batch succeeds completely or leaves the database unchanged.
class SubmitGrades
  def self.call(entries)
    raise ArgumentError, "Entries must be a non-empty array of at most 500 grades" unless entries.is_a?(Array) && entries.size.between?(1, 500)
    seen = Set.new
    Grade.transaction do
      entries.map.with_index do |entry, index|
        begin
          raise ArgumentError, "Each entry must be an object" unless entry.respond_to?(:fetch) && !entry.is_a?(Array)
          course = Course.find_by!(code: entry.fetch("course_code").to_s.strip.upcase, semester: entry.fetch("semester"))
          # Serializes grade imports against assessment-plan edits for this course.
          course.lock!
          enrollment = course.enrollments.find_by!(student_id: entry.fetch("student_id"))
          assessment = course.assessments.find_by!(title: entry.fetch("assessment_title"))
          key = [enrollment.id, assessment.id]
          raise ArgumentError, "Duplicate student/assessment in batch" unless seen.add?(key)
          grade = enrollment.grades.find_or_initialize_by(assessment: assessment)
          grade.update!(value: entry.fetch("grade"))
          grade
        rescue KeyError, ActiveRecord::RecordNotFound, ActiveRecord::RecordInvalid, ArgumentError => e
          detail = e.is_a?(ActiveRecord::RecordNotFound) ? "Course, enrolled student or assessment not found" : e.message
          raise ArgumentError, "Entry #{index + 1}: #{detail}"
        end
      end
    end
  end
end
