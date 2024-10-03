class CreateSessions < ActiveRecord::Migration[7.2]
  def change
    create_table :sessions, id: false do |t|
      # 26 characters for VARCHAR(26) in PostgreSQL
      t.binary :id, limit: 16, primary_key: true
      t.binary :user_id, limit: 16, null: false
      t.integer :issued_at, null: false
      t.integer :expires_at, null: false
    end
  end
end
