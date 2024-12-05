class CreateLeetcodeAttempts < ActiveRecord::Migration[7.2]
  def change
    create_table :leetcode_attempts do |t|
      t.references :leetcode, null: false, foreign_key: { to_table: :leetcodes }, type: :integer
      t.string :user_id, limit: 26, null: false
      t.boolean :solved, null: false
      t.string :notes, limit: 2000
      t.timestamps

      t.foreign_key :users, column: :user_id, on_delete: :cascade
    end
  end
end
