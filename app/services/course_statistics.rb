class CourseStatistics
  def self.call(course)
    values = course.enrollments.includes(:grades).filter_map { |enrollment| GradeSummary.call(enrollment)[:overall_grade] }
    mean = values.any? ? values.sum / values.size : nil
    { count: values.size, min: values.min, max: values.max, mean: mean&.round(2),
      standard_deviation: mean && Math.sqrt(values.sum { |value| (value - mean)**2 } / values.size).round(2),
      enrolled_count: course.enrollments.size, basis: "Completed weighted overall grades; population standard deviation" }
  end
end
