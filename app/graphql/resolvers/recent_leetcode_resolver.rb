# frozen_string_literal: true

class Resolvers::RecentLeetcodeResolver < Resolvers::BaseResolver
  type [Types::LeetcodeType], null: false

  def resolve
    user_id = context[:get_user_id_from_cookie].call(context[:cookies][:trackitall_session_id])
    raise GraphQL::ExecutionError, 'unauthorized' if user_id.nil?

    query = LeetcodeAttempt.select(:leetcode_id).where(user_id:).order(created_at: :desc)
    Leetcode.where(id: query.pluck(:leetcode_id)).limit(3)
  rescue StandardError => e
    raise GraphQL::ExecutionError, "An error occurred: #{e.message}"
  end
end

# WITH RankedAttempts AS (
#     SELECT
#         leetcode_id,
#         created_at,
#         ROW_NUMBER() OVER (PARTITION BY leetcode_id ORDER BY created_at DESC) AS rn
#     FROM leetcode_attempts
# )
# SELECT leetcode_id
# FROM RankedAttempts
# WHERE rn = 1
# ORDER BY created_at DESC
# LIMIT 3;
