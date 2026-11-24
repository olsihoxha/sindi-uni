class Course < ApplicationRecord
  has_many :enrollments, dependent: :destroy
  has_many :students, through: :enrollments
  has_many :assessments, dependent: :destroy
  normalizes :code, with: ->(value) { value.strip.upcase }
  normalizes :name, :semester, with: ->(value) { value.strip }
  before_validation :set_semester_order
  validates :code, presence: true, length: { in: 5..6 }, uniqueness: true
  validates :name, presence: true, length: { maximum: 50 }
  validates :semester, presence: true, length: { maximum: 10 }
  validates :catalog_data, length: { maximum: 500 }
  scope :recent, -> { where(semester: Semester.recent).order(semester_order: :desc, code: :asc) }

  def total_weight = assessments.sum(:weight)
  def assessment_plan_complete? = total_weight == BigDecimal("1")

  private

  def set_semester_order
    self.semester_order = Semester.order(semester)
  rescue ArgumentError => e
    errors.add(:semester, e.message)
  end
end
