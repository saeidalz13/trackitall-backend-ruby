# frozen_string_literal: true

module Types
  class LeetcodeType < Types::BaseObject
    field :id, ID, null: false
    field :title, String, null: false
    field :difficulty, String, null: false
    field :link, String, null: false
    field :acc_rate, Float
    field :paid_only, Boolean
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false
    field :updated_at, GraphQL::Types::ISO8601DateTime, null: false
  end
end
