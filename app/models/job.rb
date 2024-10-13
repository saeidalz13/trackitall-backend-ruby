class Job < ApplicationRecord
  belongs_to :user

  has_many :interview_questions, dependent: :destroy, class_name: 'InterviewQuestion'

  validates :position, presence: true
  validates :company_name, presence: true
end
