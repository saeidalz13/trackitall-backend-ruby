class TechnicalChallenge < ApplicationRecord
  enum :tag, { leetcode: 'leetcode', project: 'project' }

  belongs_to :user
  belongs_to :job

  validates :question, presence: true
  validates_inclusion_of :tag, in: %w[leetcode project]
end
