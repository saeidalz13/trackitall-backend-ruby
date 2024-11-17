# frozen_string_literal: true

module Types
  class LeetcodeType < Types::BaseObject
    field :id, ID, null: false
    field :user_id, String, null: false
    field :title, String, null: false
    field :difficulty, Integer, null: false
    field :link, String
    field :dsa, String
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false
    field :updated_at, GraphQL::Types::ISO8601DateTime, null: false
  end
end
