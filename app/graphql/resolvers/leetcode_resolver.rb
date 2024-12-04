class Resolvers::LeetcodeResolver < Resolvers::BaseResolver
  type Types::LeetcodeQueryResponseType, null: false

  argument :limit, Integer, required: true, description: 'Limit number for leetcode problems'
  argument :offset, Integer, required: true, description: 'Offset number for leetcode problems'
  argument :difficulty, String, required: true, description: 'Search for difficulty'
  argument :solved_filter, String, required: true, description: 'Search for all, solved, or unsolved problems'
  argument :tag_filter, String, required: true, description: 'Search for leetcodes with specific tag'
  argument :title_filter, String, required: true, description: 'Search for leetcodes by their title'

  def resolve(limit:, offset:, difficulty:, solved_filter:, tag_filter:, title_filter:)
    user_id = context[:get_user_id_from_cookie].call(context[:cookies][:trackitall_session_id])
    raise GraphQL::ExecutionError, 'unauthorized' if user_id.nil?

    query = Leetcode.all
    query = query.where(difficulty:) unless difficulty.blank?

    if tag_filter != ''
      lt_ids = LeetcodeTag.where(tag: tag_filter).pluck(:id)
      leetcode_ids = LeetcodeWithTag.where(leetcode_tag_id: lt_ids).pluck(:leetcode_id)
      query = query.where(id: leetcode_ids)
    end

    if solved_filter != 'all'
      solved_ids = LeetcodeAttempt.where(user_id:, solved: true).pluck(:leetcode_id)

      if solved_filter == 'solved'
        query = query.where(id: solved_ids)
      elsif solved_filter == 'unsolved'
        query = query.where.not(id: solved_ids)
      end
    end

    query = query.where('title ILIKE ?', "%#{title_filter}%") if title_filter != ''

    { count: query.count, problems: query.limit(limit).offset(offset) }
  end
end
