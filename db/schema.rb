# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_11_24_000000) do
  create_table "assessments", force: :cascade do |t|
    t.integer "course_id", null: false
    t.string "title", limit: 30, null: false
    t.decimal "weight", precision: 8, scale: 6, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["course_id", "title"], name: "index_assessments_on_course_id_and_title", unique: true
    t.index ["course_id"], name: "index_assessments_on_course_id"
    t.check_constraint "weight >= 0 AND weight <= 1", name: "valid_weight"
  end

  create_table "courses", force: :cascade do |t|
    t.string "code", limit: 6, null: false
    t.string "name", limit: 50, null: false
    t.string "semester", limit: 10, null: false
    t.integer "semester_order", null: false
    t.text "catalog_data"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["code"], name: "index_courses_on_code", unique: true
    t.index ["semester_order"], name: "index_courses_on_semester_order"
  end

  create_table "enrollments", force: :cascade do |t|
    t.integer "course_id", null: false
    t.integer "student_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["course_id", "student_id"], name: "index_enrollments_on_course_id_and_student_id", unique: true
    t.index ["course_id"], name: "index_enrollments_on_course_id"
    t.index ["student_id"], name: "index_enrollments_on_student_id"
  end

  create_table "grades", force: :cascade do |t|
    t.integer "enrollment_id", null: false
    t.integer "assessment_id", null: false
    t.integer "value", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["assessment_id"], name: "index_grades_on_assessment_id"
    t.index ["enrollment_id", "assessment_id"], name: "index_grades_on_enrollment_id_and_assessment_id", unique: true
    t.index ["enrollment_id"], name: "index_grades_on_enrollment_id"
    t.check_constraint "value >= 0 AND value <= 120", name: "valid_grade"
  end

  create_table "users", force: :cascade do |t|
    t.string "name", limit: 30, null: false
    t.string "surname", limit: 30, null: false
    t.string "email", null: false
    t.string "password_digest", null: false
    t.string "role", default: "student", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index "lower(email)", name: "index_users_on_lower_email", unique: true
    t.check_constraint "role IN ('instructor', 'student')", name: "valid_user_role"
  end

  add_foreign_key "assessments", "courses"
  add_foreign_key "enrollments", "courses"
  add_foreign_key "enrollments", "users", column: "student_id"
  add_foreign_key "grades", "assessments"
  add_foreign_key "grades", "enrollments"
end
