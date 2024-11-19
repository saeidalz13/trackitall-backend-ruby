class CreateLeetcodeAttempts < ActiveRecord::Migration[7.2]
  def change
    create_table :leetcode_attempts do |t|
      t.references :leetcode, null: false, foreign_key: { to_table: :leetcodes }, type: :string
      t.boolean :solved, null: false
      t.string :notes, limit: 2000
      t.timestamps
    end
  end
end
