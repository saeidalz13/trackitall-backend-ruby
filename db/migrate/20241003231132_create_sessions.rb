class CreateSessions < ActiveRecord::Migration[7.2]
  def change
    create_table :sessions, id: false do |t|
      # 26 characters for VARCHAR(26) in PostgreSQL
      t.string :id, limit: 26, primary_key: true
      t.string :user_id, limit: 26, null: false
      t.integer :issued_at, null: false
      t.integer :expires_at, null: false
      
      t.foreign_key :users, column: :user_id, on_delete: :cascade
    end
  end
end
