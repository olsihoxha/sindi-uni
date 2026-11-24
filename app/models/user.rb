class User < ApplicationRecord
  has_secure_password
  has_many :enrollments, foreign_key: :student_id, dependent: :destroy, inverse_of: :student
  has_many :courses, through: :enrollments
  normalizes :email, with: ->(email) { email.strip.downcase }
  normalizes :name, :surname, with: ->(value) { value.strip }
  scope :students, -> { where(role: "student") }
  validates :name, :surname, presence: true, length: { maximum: 30 }
  validates :email, presence: true, uniqueness: { case_sensitive: false }, format: { with: /\A[^\s@]+@[^\s@]+\.[^\s@]+\z/ }
  validates :role, inclusion: { in: %w[instructor student] }
  validates :password, length: { minimum: 8 }, format: { with: /\A(?=.*[a-z])(?=.*[A-Z])(?=.*[0-9]).+\z/m, message: "must contain uppercase, lowercase and a number" }, if: -> { password.present? || new_record? }
  validate :combined_name_length

  def instructor? = role == "instructor"
  def full_name = "#{name} #{surname}"

  private

  def combined_name_length
    errors.add(:base, "Name and surname together must not exceed 50 characters") if name.to_s.length + surname.to_s.length > 50
  end
end
