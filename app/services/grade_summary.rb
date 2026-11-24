class GradeSummary
  def self.call(enrollment)
    assessments = enrollment.course.assessments.to_a
    grades = enrollment.grades.to_a.index_by(&:assessment_id)
    earned = assessments.sum { |item| item.weight * (grades[item.id]&.value || 0) }
    complete = assessments.any? && enrollment.course.assessment_plan_complete? && assessments.all? { |item| grades.key?(item.id) }
    { overall_grade: complete ? earned.round(2).to_f : nil, earned_points: earned.round(2).to_f,
      graded_count: grades.size, assessment_count: assessments.size, complete: complete }
  end
end
