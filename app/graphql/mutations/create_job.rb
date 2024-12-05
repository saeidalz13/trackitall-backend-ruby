module Mutations
  class CreateJob < BaseMutation
    description 'creates a new job application'

    argument :position, String, required: true
    argument :company_name, String, required: true
    argument :applied_date, GraphQL::Types::ISO8601DateTime, required: false
    argument :link, String, required: false
    argument :description, String, required: false

    field :id, String, null: true
    field :applied_date, GraphQL::Types::ISO8601DateTime, null: true
    field :errors, [String], null: false

    def resolve(position:, company_name:, applied_date:, link:, description:)
      user_id = context[:get_user_id_from_cookie].call(context[:cookies][:trackitall_session_id])
      return { job: nil, applied_date: nil, errors: ['unauthorized'] } if user_id.nil?

      job = Job.new(id: ULID.generate, user_id:, position:, company_name:, applied_date:, link:, description:)

      if job.save
        { id: job.id, applied_date: job.applied_date, errors: [] }
      else
        { job: nil, applied_date: nil, errors: job.errors.full_messages }
      end
    end
  end
end
