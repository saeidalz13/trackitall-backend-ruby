class User < ApplicationRecord
  has_one :session, dependent: :destroy, class_name: 'Session'
  has_many :jobs, dependent: :destroy, class_name: 'Job'
  has_many :interview_questions, dependent: :destroy, class_name: 'InterviewQuestion'

  validates :email, presence: true, uniqueness: true
  validates :password, presence: true
end
