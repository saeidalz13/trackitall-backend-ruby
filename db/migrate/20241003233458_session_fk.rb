class SessionFk < ActiveRecord::Migration[7.2]
  def change
    add_foreign_key :sessions, :users, column: :user_id, primary_key: :id
  end
end
