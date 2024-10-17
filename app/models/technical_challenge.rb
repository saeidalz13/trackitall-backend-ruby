class TechnicalChallenge < ApplicationRecord
  belongs_to :user
  belongs_to :job

  validates :question, presence: true
end
