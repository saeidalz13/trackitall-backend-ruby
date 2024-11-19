# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

require 'net/http'
require 'uri'
require 'json'

# Define the URL and HTTP method
uri = URI.parse('https://leetcode.com/graphql')
http = Net::HTTP.new(uri.host, uri.port)
http.use_ssl = true

# Create the request
request = Net::HTTP::Post.new(uri.path)
request['Content-Type'] = 'application/json'
request['Cookie'] = 'LEETCODE_SESSION=<LEETCODE_SESSION>; csrftoken=<csrftoken>'
request['X-CSRFToken'] = '<csrftoken>'

# JSON payload
payload = {
  query: <<~GRAPHQL,
    query problemsetQuestionList($categorySlug: String, $limit: Int, $skip: Int, $filters: QuestionListFilterInput) {
      problemsetQuestionList: questionList(
        categorySlug: $categorySlug
        limit: $limit
        skip: $skip
        filters: $filters
      ) {
        total: totalNum
        questions: data {
          acRate
          difficulty
          frontendQuestionId: questionFrontendId
          isFavor
          paidOnly: isPaidOnly
          title
          titleSlug
          topicTags {
            name
            id
            slug
          }
        }
      }
    }
  GRAPHQL
  variables: {
    categorySlug: '',
    skip: 0,
    limit: 4000,
    filters: {}
  }
}.to_json

request.body = payload

# Execute the request and get the response
response = http.request(request)

if response.code != '200'
  puts 'Failed to fetch leetcode from GQL endpoint'
else
  parsed_body = JSON.parse(response.body)
  questions = parsed_body['data']['problemsetQuestionList']['questions']

  questions.each do |question|
    Leetcode.create!(
      id: question['frontendQuestionId'],
      title: question['title'],
      difficulty: question['difficulty'].downcase,
      link: "https://leetcode.com/problems/#{question['titleSlug']}",
      acc_rate: question['acRate'],
      paid_only: question['paidOnly']
    )
  rescue ActiveRecord::RecordNotUnique, PG::UniqueViolation
    # ignore this since I ignore the repetition error
    next
  end
end
