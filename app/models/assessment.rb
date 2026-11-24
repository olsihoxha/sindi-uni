class Assessment < ApplicationRecord
  belongs_to :course
  has_many :grades, dependent: :destroy
  normalizes :title, with: ->(value) { value.strip }
  validates :title, presence: true, length: { maximum: 30 }, uniqueness: { scope: :course_id }
  validates :weight, presence: true, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 1 }
  validate :valid_course_total
  before_destroy :preserve_graded_plan

  private

  def valid_course_total
    return unless course && weight && errors[:weight].empty?
    others = course.assessments.where.not(id: id).sum(:weight)
    total = others + weight
    errors.add(:weight, "would make the course total exceed 100%") if total > 1
    if course.assessments.joins(:grades).exists? && total != 1
      errors.add(:weight, "cannot change the 100% total while grades exist")
    end
  end

  def preserve_graded_plan
    return if destroyed_by_association || weight.zero? || !course.assessments.joins(:grades).exists?
    errors.add(:base, "Delete the course's grades before removing a weighted assessment")
    throw :abort
  end
end
