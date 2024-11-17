# frozen_string_literal: true

module Types
  class MutationType < Types::BaseObject
    field :create_job, mutation: Mutations::CreateJob
  end
end
