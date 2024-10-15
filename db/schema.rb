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

ActiveRecord::Schema[7.2].define(version: 2024_10_12_194029) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "interview_questions", force: :cascade do |t|
    t.string "user_id", limit: 26, null: false
    t.string "job_id", limit: 26, null: false
    t.string "question", null: false
    t.text "response"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "job_id", "question"], name: "index_interview_questions_on_user_id_and_job_id_and_question", unique: true
  end

  create_table "jobs", id: { type: :string, limit: 26 }, force: :cascade do |t|
    t.string "user_id", limit: 26, null: false
    t.string "position", limit: 50, null: false
    t.string "company_name", limit: 50, null: false
    t.datetime "applied_date", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.string "link", limit: 500
    t.string "description", limit: 15000
    t.string "ai_insight", limit: 10000
    t.string "resume_path", limit: 1000
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_name"], name: "index_jobs_on_company_name"
    t.index ["position"], name: "index_jobs_on_position"
    t.index ["user_id"], name: "index_jobs_on_user_id"
  end

  create_table "sessions", id: { type: :string, limit: 26 }, force: :cascade do |t|
    t.string "user_id", limit: 26, null: false
    t.integer "issued_at", null: false
    t.integer "expires_at", null: false
  end

  create_table "users", id: { type: :string, limit: 26 }, force: :cascade do |t|
    t.string "email", null: false
    t.string "password", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  add_foreign_key "interview_questions", "jobs", on_delete: :cascade
  add_foreign_key "interview_questions", "users", on_delete: :cascade
  add_foreign_key "jobs", "users", on_delete: :cascade
  add_foreign_key "sessions", "users", on_delete: :cascade
end
