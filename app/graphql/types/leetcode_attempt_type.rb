# frozen_string_literal: true

module Types
  class LeetcodeAttemptType < Types::BaseObject
    field :id, ID, null: false
    field :leetcode_id, Integer, null: false
    field :user_id, String, null: false
    field :solved, Boolean, null: false
    field :notes, String
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false
    field :updated_at, GraphQL::Types::ISO8601DateTime, null: false
  end
end
