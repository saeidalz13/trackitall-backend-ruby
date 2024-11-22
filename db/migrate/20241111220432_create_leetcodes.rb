class CreateLeetcodes < ActiveRecord::Migration[7.2]
  def change
    create_table :leetcodes, id: false do |t|
      t.integer :id, primary_key: true
      t.string :title, limit: 100, null: false
      t.string :difficulty, null: false
      t.string :link, limit: 500, null: false
      t.float :acc_rate, null: true
      t.boolean :paid_only, null: true
      t.timestamps

      t.check_constraint "difficulty IN ('easy', 'medium', 'hard')"
    end
  end
end
