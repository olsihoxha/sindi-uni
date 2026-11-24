class CreateGradebook < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      t.string :name, null: false, limit: 30
      t.string :surname, null: false, limit: 30
      t.string :email, null: false
      t.string :password_digest, null: false
      t.string :role, null: false, default: "student"
      t.timestamps
    end
    add_index :users, "lower(email)", unique: true
    add_check_constraint :users, "role IN ('instructor', 'student')", name: "valid_user_role"
    create_table :courses do |t|
      t.string :code, null: false, limit: 6
      t.string :name, null: false, limit: 50
      t.string :semester, null: false, limit: 10
      t.integer :semester_order, null: false
      t.text :catalog_data
      t.timestamps
    end
    add_index :courses, :code, unique: true
    add_index :courses, :semester_order
    create_table :assessments do |t|
      t.references :course, null: false, foreign_key: true
      t.string :title, null: false, limit: 30
      t.decimal :weight, precision: 8, scale: 6, null: false
      t.timestamps
    end
    add_index :assessments, [:course_id, :title], unique: true
    add_check_constraint :assessments, "weight >= 0 AND weight <= 1", name: "valid_weight"
    create_table :enrollments do |t|
      t.references :course, null: false, foreign_key: true
      t.references :student, null: false, foreign_key: { to_table: :users }
      t.timestamps
    end
    add_index :enrollments, [:course_id, :student_id], unique: true
    create_table :grades do |t|
      t.references :enrollment, null: false, foreign_key: true
      t.references :assessment, null: false, foreign_key: true
      t.integer :value, null: false
      t.timestamps
    end
    add_index :grades, [:enrollment_id, :assessment_id], unique: true
    add_check_constraint :grades, "value >= 0 AND value <= 120", name: "valid_grade"
  end
end
