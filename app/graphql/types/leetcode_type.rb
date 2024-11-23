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

    field :attempts, [Types::LeetcodeAttemptType], null: false
    def attempts
      LeetcodeAttempt.where(leetcode_id: object.id).presence || []
    end

    field :tags, [Types::LeetcodeTagType], null: false
    def tags
      lcwt = LeetcodeWithTag.where(leetcode_id: object.id)
      return [] unless lcwt.exists?

      LeetcodeTag.where(id: lcwt.pluck(:leetcode_tag_id))
    end
  end
end
