class CreateJobs < ActiveRecord::Migration[7.2]
  def change
    create_table :jobs, id: false do |t|
      t.string :user_id, limit: 26, null: false
      t.string :position, limit: 50, null: false 
      t.string :company_name, limit: 50, null: false
      t.datetime :applied_date, null: false, default: -> { 'CURRENT_TIMESTAMP' }
      t.string :link, limit: 500, null: true
      t.string :description, limit: 15000, null: true
      t.string :ai_insight, limit: 10000, null: true
      t.string :resume_path, limit: 1000, null: true
      t.timestamps

      t.foreign_key :users, column: :user_id, on_delete: :cascade
    end
    add_index :jobs, :user_id
    add_index :jobs, :position
    add_index :jobs, :company_name
  end
end
