# frozen_string_literal: true

module Types
  class JobType < Types::BaseObject
    field :id, ID, null: false
    field :user_id, String, null: false
    field :position, String, null: false
    field :company_name, String, null: false
    field :applied_date, GraphQL::Types::ISO8601DateTime, null: false
    field :link, String
    field :description, String
    field :ai_insight, String
    field :resume_path, String
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false
    field :updated_at, GraphQL::Types::ISO8601DateTime, null: false
    field :resume_content, String

    # added custom
    field :interview_questions, [Types::InterviewQuestionType]
    field :technicall_challenges, [Types::TechnicalChallengeType]
  end
end
