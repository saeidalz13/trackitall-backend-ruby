class CreateLeetcodeWithTags < ActiveRecord::Migration[7.2]
  def change
    create_table :leetcode_with_tags do |t|
      t.references :leetcode, null: false, foreign_key: { to_table: :leetcodes }, type: :integer
      t.references :leetcode_tag, null: false, foreign_key: { to_table: :leetcode_tags }, type: :string
      t.timestamps
    end
  end
end
