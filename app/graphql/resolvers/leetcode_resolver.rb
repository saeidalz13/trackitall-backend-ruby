class Resolvers::LeetcodeResolver < Resolvers::BaseResolver
  type [Types::LeetcodeType], null: false

  argument :limit, Integer, required: true, description: 'Limit number for leetcode problems'
  argument :offset, Integer, required: true, description: 'Offset number for leetcode problems'
  argument :difficulty, String, required: true, description: 'Search for difficulty'

  def resolve(limit:, offset:, difficulty:)
    query = Leetcode.limit(limit).offset(offset)
    query = query.where(difficulty:) unless difficulty.blank?
    query
  end
end
