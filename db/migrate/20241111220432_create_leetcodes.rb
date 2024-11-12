class CreateLeetcodes < ActiveRecord::Migration[7.2]
  def change
    create_table :leetcodes do |t|
      t.string :user_id, limit: 26, null: false
      t.string :title, limit: 100, null: false
      t.integer :difficulty, null: false
      t.string :link, limit: 500, null: true
      t.string :dsa, limit: 100, null: true
      t.timestamps

      t.check_constraint 'difficulty IN (0, 1, 2)'
      t.foreign_key :users, column: :user_id, on_delete: :cascade
    end
  end
end
