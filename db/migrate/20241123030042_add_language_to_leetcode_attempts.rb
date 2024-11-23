class AddLanguageToLeetcodeAttempts < ActiveRecord::Migration[7.2]
  def change
    add_column :leetcode_attempts, :language, :string
    execute <<~SQL
      ALTER TABLE leetcode_attempts
      ADD CONSTRAINT language_check
      CHECK (language IN (
        'c', 'c#', 'c++', 'dart', 'elixir', 'erlang', 'go',
        'java', 'javascript', 'kotlin', 'php', 'python',
        'racket', 'ruby', 'rust', 'scala',
        'swift', 'typescript'
      ));
    SQL
  end
end
