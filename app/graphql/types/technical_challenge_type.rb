# frozen_string_literal: true

module Types
  class TechnicalChallengeType < Types::BaseObject
    field :id, ID, null: false
    field :user_id, String, null: false
    field :job_id, String, null: false
    field :question, String, null: false
    field :tag, String, null: false
    field :ai_hint, String
    field :user_solution, String
    field :ai_solution, String
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false
    field :updated_at, GraphQL::Types::ISO8601DateTime, null: false
  end
end
