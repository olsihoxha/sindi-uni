class Grade < ApplicationRecord
  belongs_to :enrollment
  belongs_to :assessment
  validates :value, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 120 }
  validates :assessment_id, uniqueness: { scope: :enrollment_id, message: "already has a grade for this student" }
  validate :matching_course

  private

  def matching_course
    return unless assessment && enrollment
    errors.add(:assessment, "must belong to the enrolled course") if assessment.course_id != enrollment.course_id
    errors.add(:base, "Assessment weights must total 100% before entering grades") unless enrollment.course.assessment_plan_complete?
  end
end
