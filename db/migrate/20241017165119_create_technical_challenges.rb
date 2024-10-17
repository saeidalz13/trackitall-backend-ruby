class CreateTechnicalChallenges < ActiveRecord::Migration[7.2]
  def change
    create_table :technical_challenges do |t|
      t.string :user_id, limit: 26, null: false
      t.string :job_id, limit: 26, null: false
      t.string :question, limit: 5000, null: false
      t.string :user_solution, limit: 50_000
      t.string :ai_solution, limit: 50_000
      t.timestamps

      t.foreign_key :users, column: :user_id, on_delete: :cascade
      t.foreign_key :jobs, column: :job_id, on_delete: :cascade
    end
    add_index :technical_challenges, %i[user_id job_id question], unique: true
  end
end
