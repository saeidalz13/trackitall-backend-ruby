class InterviewQuestion < ApplicationRecord
  DEFAULT_QUESTIONS = [
    'Can you introduce yourself and share a bit about your background?',
    'What does your ideal role look like, and why does it appeal to you?',
    'What project are you most proud of, and what was your role in it?',
    'What attracted you to our company, and what do you know about us?',
    'What motivates your decision to transition from your current role?',
    'Describe a time when you had to convince a team member or stakeholder to see things your way.',
    'Share an experience where you faced failure, and what you learned from it.',
    'Have you ever encountered disagreements or conflicts with colleagues? How did you resolve them?',
    'If I asked your previous colleagues to describe you, what would they say?',
    'What situations tend to frustrate you the most, and how do you handle them?',
    'What was the most challenging technical problem you solved recently, and how did you approach it?',
    "Have you ever faced a situation where you couldn't meet a deadline? How did you handle it?",
    'Tell me about a time when you had to work under pressure to meet a tight deadline.',
    'How do you prioritize tasks when faced with multiple high-priority projects?',
    'Describe a situation where you had to adapt quickly to a significant change in the workplace.'
  ].freeze

  belongs_to :user
  belongs_to :job

  validates :question, presence: true

  def self.add_default_questions(user_id, job_id)
    DEFAULT_QUESTIONS.map { |question| create!(question:, user_id:, job_id:) }
    true
  rescue StandardError => e
    Rails.logger.error("Failed to add questions: #{e.message}")
    false
  end
end
