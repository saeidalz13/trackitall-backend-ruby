# frozen_string_literal: true

module Types
  class MutationType < Types::BaseObject
    field :create_job, mutation: Mutations::CreateJob
    field :create_leetcode_attempt, mutation: Mutations::CreateLeetcodeAttempt
  end
end
