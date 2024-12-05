module Types
  class LeetcodeQueryResponseType < Types::BaseObject
    field :count, Integer, null: false, description: 'Total count of problems'
    field :problems, [Types::LeetcodeType], null: false, description: 'List of leetcode problems'
  end
end
