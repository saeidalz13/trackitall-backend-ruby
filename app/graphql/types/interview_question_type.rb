# frozen_string_literal: true

module Types
  class InterviewQuestionType < Types::BaseObject
    field :id, ID, null: false
    field :user_id, String, null: false
    field :job_id, String, null: false
    field :question, String, null: false
    field :response, String
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false
    field :updated_at, GraphQL::Types::ISO8601DateTime, null: false
  end
end
