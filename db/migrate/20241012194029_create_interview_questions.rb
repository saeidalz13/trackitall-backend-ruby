class CreateInterviewQuestions < ActiveRecord::Migration[7.2]
  def change
    create_table :interview_questions do |t|
      t.string :question, null: false
      t.string :user_id, null: false
      t.timestamps

      t.foreign_key :users, column: :user_id, on_delete: :cascade
    end
    add_index :interview_questions, %i[user_id question], unique: true
  end
end
