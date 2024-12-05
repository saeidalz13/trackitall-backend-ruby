# frozen_string_literal: true

module Types
  class QueryType < Types::BaseObject
    field :node, Types::NodeType, null: true, description: 'Fetches an object given its ID.' do
      argument :id, ID, required: true, description: 'ID of the object.'
    end

    def node(id:)
      context.schema.object_from_id(id, context)
    end

    field :nodes, [Types::NodeType, { null: true }], null: true,
                                                     description: 'Fetches a list of objects given a list of IDs.' do
      argument :ids, [ID], required: true, description: 'IDs of the objects.'
    end

    def nodes(ids:)
      ids.map { |id| context.schema.object_from_id(id, context) }
    end

    # Add root-level fields here.
    # They will be entry points for queries on your schema.

    # get all the jobs
    field :jobs, [Types::JobType] do
      argument :limit, Integer, required: false, description: 'Limit number of jobs sent'
    end
    def jobs(limit:)
      limit ? Job.limit(limit) : Job.all
    end

    field :leetcodes, resolver: Resolvers::LeetcodeResolver
    field :recent_leetcodes, resolver: Resolvers::RecentLeetcodeResolver
  end
end

# field :interview_info, [Types::TechnicalChallengeType, Types::InterviewQuestionType] do
#   argument :job_id, ID, required: true, description: 'Fetches all behavioral and technical interview questions'
# end
# def interview_info(job_id:)
# end
