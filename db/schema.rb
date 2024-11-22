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

ActiveRecord::Schema[7.2].define(version: 2024_11_19_164410) do
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
    t.text "resume_content"
    t.index ["company_name"], name: "index_jobs_on_company_name"
    t.index ["position"], name: "index_jobs_on_position"
    t.index ["user_id"], name: "index_jobs_on_user_id"
  end

  create_table "leetcode_attempts", force: :cascade do |t|
    t.integer "leetcode_id", null: false
    t.string "user_id", limit: 26, null: false
    t.boolean "solved", null: false
    t.string "notes", limit: 2000
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["leetcode_id"], name: "index_leetcode_attempts_on_leetcode_id"
  end

  create_table "leetcode_tags", id: :string, force: :cascade do |t|
    t.string "tag"
    t.string "link", limit: 500, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["tag"], name: "unique_tags", unique: true
  end

  create_table "leetcode_with_tags", force: :cascade do |t|
    t.integer "leetcode_id", null: false
    t.string "leetcode_tag_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["leetcode_id"], name: "index_leetcode_with_tags_on_leetcode_id"
    t.index ["leetcode_tag_id"], name: "index_leetcode_with_tags_on_leetcode_tag_id"
  end

  create_table "leetcodes", id: :serial, force: :cascade do |t|
    t.string "title", limit: 100, null: false
    t.string "difficulty", null: false
    t.string "link", limit: 500, null: false
    t.float "acc_rate"
    t.boolean "paid_only"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.check_constraint "difficulty::text = ANY (ARRAY['easy'::character varying, 'medium'::character varying, 'hard'::character varying]::text[])"
  end

  create_table "sessions", id: { type: :string, limit: 26 }, force: :cascade do |t|
    t.string "user_id", limit: 26, null: false
    t.integer "issued_at", null: false
    t.integer "expires_at", null: false
  end

  create_table "technical_challenges", force: :cascade do |t|
    t.string "user_id", limit: 26, null: false
    t.string "job_id", limit: 26, null: false
    t.string "question", limit: 5000, null: false
    t.string "tag", limit: 30, null: false
    t.string "ai_hint", limit: 10000
    t.string "user_solution", limit: 50000
    t.string "ai_solution", limit: 50000
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "job_id", "question"], name: "index_technical_challenges_on_user_id_and_job_id_and_question", unique: true
    t.check_constraint "tag::text = ANY (ARRAY['leetcode'::character varying, 'project'::character varying, 'custom'::character varying]::text[])"
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
  add_foreign_key "leetcode_attempts", "leetcodes"
  add_foreign_key "leetcode_attempts", "users", on_delete: :cascade
  add_foreign_key "leetcode_with_tags", "leetcode_tags"
  add_foreign_key "leetcode_with_tags", "leetcodes"
  add_foreign_key "sessions", "users", on_delete: :cascade
  add_foreign_key "technical_challenges", "jobs", on_delete: :cascade
  add_foreign_key "technical_challenges", "users", on_delete: :cascade
end
