class CreateLeetcodeTags < ActiveRecord::Migration[7.2]
  def change
    create_table :leetcode_tags, id: false do |t|
      t.string :id, primary_key: true
      t.string :tag, index: { unique: true, name: 'unique_tags' }
      t.string :link, limit: 500, null: false
      t.timestamps
    end
  end
end
