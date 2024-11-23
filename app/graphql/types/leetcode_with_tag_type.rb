# frozen_string_literal: true

module Types
  class LeetcodeWithTagType < Types::BaseObject
    field :id, ID, null: false
    field :leetcode_id, Integer, null: false
    field :leetcode_tag_id, String, null: false
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false
    field :updated_at, GraphQL::Types::ISO8601DateTime, null: false
  end
end
