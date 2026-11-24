class Enrollment < ApplicationRecord
  belongs_to :course
  belongs_to :student, class_name: "User", inverse_of: :enrollments
  has_many :grades, dependent: :destroy
  validates :student_id, uniqueness: { scope: :course_id, message: "is already enrolled in this course" }
  validate :student_role

  private

  def student_role
    errors.add(:student, "must have the student role") if student && student.instructor?
  end
end
