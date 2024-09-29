class CreateUsers < ActiveRecord::Migration[7.2]
  def change
    create_table :users, id: false do |t|
      # 26 characters for VARCHAR(26) in PostgreSQL
      t.binary :id, limit: 16, primary_key: true
      t.string :email, null: false
      t.index :email, unique: true
      t.string :password, null: false
      t.timestamps
    end
  end
end
