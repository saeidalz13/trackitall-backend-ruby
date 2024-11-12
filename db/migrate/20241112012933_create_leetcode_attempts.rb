class CreateLeetcodeAttempts < ActiveRecord::Migration[7.2]
  def change
    create_table :leetcode_attempts do |t|
      t.references :leetcode, null: false, foreign_key: true, index: true
      t.boolean :succeed, null: false
      t.text :notes, limit: 2000
      t.timestamps
    end
  end
end
