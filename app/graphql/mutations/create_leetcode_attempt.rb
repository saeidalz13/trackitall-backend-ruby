module Mutations
  class CreateLeetcodeAttempt < BaseMutation
    description 'creates a new leetcode attempt'

    argument :leetcode_id, Integer, required: true
    argument :language, String, required: true
    argument :solved, Boolean, required: true
    argument :notes, String, required: true

    field :leetcode_attempt, Types::LeetcodeAttemptType
    field :errors, [String], null: false

    def resolve(leetcode_id:, language:, solved:, notes:)
      user_id = context[:get_user_id_from_cookie].call(context[:cookies][:trackitall_session_id])
      return { job: nil, applied_date: nil, errors: ['unauthorized'] } if user_id.nil?

      leetcode_attempt = LeetcodeAttempt.new(user_id:, leetcode_id:, language:, solved:, notes:)
      if leetcode_attempt.save
        { leetcode_attempt:, errors: [] }
      else
        { leetcode_attempt: nil, errors: leetcode_attempt.errors.full_messages }
      end
    end
  end
end
