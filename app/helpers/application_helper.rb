module ApplicationHelper
  def grade_label(summary)
    summary[:complete] ? number_with_precision(summary[:overall_grade], precision: 1) : "In progress"
  end
  def percentage(value) = "#{number_with_precision(value * 100, precision: 1, strip_insignificant_zeros: true)}%"
end
