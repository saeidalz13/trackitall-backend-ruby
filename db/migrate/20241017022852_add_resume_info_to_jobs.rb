class AddResumeInfoToJobs < ActiveRecord::Migration[7.2]
  def change
    add_column :jobs, :resume_content, :text
  end
end
