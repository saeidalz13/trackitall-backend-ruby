class Resolvers::LeetcodeResolver < Resolvers::BaseResolver
  type Types::LeetcodeQueryResponseType, null: false

  argument :limit, Integer, required: true, description: 'Limit number for leetcode problems'
  argument :offset, Integer, required: true, description: 'Offset number for leetcode problems'
  argument :difficulty, String, required: true, description: 'Search for difficulty'
  argument :solved_filter, String, required: true, description: 'Search for all, solved, or unsolved problems'

  def resolve(limit:, offset:, difficulty:, solved_filter:)
    user_id = context[:get_user_id_from_cookie].call(context[:cookies][:trackitall_session_id])
    raise GraphQL::ExecutionError, 'unauthorized' if user_id.nil?

    query = Leetcode.all
    query = query.where(difficulty:) unless difficulty.blank?

    if solved_filter != 'all'
      solved_ids = LeetcodeAttempt.where(user_id:, solved: true).pluck(:leetcode_id)

      if solved_filter == 'solved'
        query = query.where(id: solved_ids)
      elsif solved_filter == 'unsolved'
        query = query.where.not(id: solved_ids)
      end
    end

    { count: query.count, problems: query.limit(limit).offset(offset) }
  end
end
