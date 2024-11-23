# frozen_string_literal: true

module Types
  class LeetcodeTagType < Types::BaseObject
    field :id, ID, null: false
    field :tag, String
    field :link, String, null: false
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false
    field :updated_at, GraphQL::Types::ISO8601DateTime, null: false
  end
end
