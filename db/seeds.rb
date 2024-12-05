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

puts 'Sending request to leetcode graphql server...'

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
puts 'Waiting for response...'
response = http.request(request)

if response.code != '200'
  puts 'Failed to fetch leetcode from GQL endpoint'
  return
else
  puts 'Fetched response, parsing...'
  parsed_body = JSON.parse(response.body)
  questions = parsed_body['data']['problemsetQuestionList']['questions']

  if LeetcodeWithTag.exists?
    puts 'Seed leetcode data already exists.'
    return
  end

  leetcode_with_tags_ids = {}
  puts 'Populating leetcodes table...'
  # Populate leetcodes table
  questions.each do |question|
    lc = Leetcode.create!(
      id: question['frontendQuestionId'],
      title: question['title'],
      difficulty: question['difficulty'].downcase,
      link: "https://leetcode.com/problems/#{question['titleSlug']}",
      acc_rate: question['acRate'],
      paid_only: question['paidOnly']
    )

    puts "Leetcode added -> ID: #{lc.id}"

    # Populate leetcode_tags table
    topic_tags = question['topicTags']
    unless topic_tags.empty?
      topic_tags.each do |t|
        LeetcodeTag.create!(id: t['id'], tag: t['name'].downcase, link: "https://leetcode.com/problem-list/#{t['slug']}")
        puts "Leetcode tag added -> ID: #{t['id']}"
      rescue ActiveRecord::RecordNotUnique, PG::UniqueViolation
        break
      rescue StandardError => e
        puts e.message
      end
      leetcode_with_tags_ids[lc.id] = topic_tags
    end
  rescue ActiveRecord::RecordNotUnique, PG::UniqueViolation
    next
  rescue StandardError => e
    puts e.message
    break
  end

  return if leetcode_with_tags_ids.empty?

  puts 'Populating leetcode_with_tags table...'
  # Populate the leetcode_with_tags table
  leetcode_with_tags_ids.each do |l_id, leetcode_topic_tags|
    leetcode_topic_tags.each do |tt|
      LeetcodeWithTag.create!(leetcode_id: l_id, leetcode_tag_id: tt['id'])
    rescue ActiveRecord::RecordNotUnique, PG::UniqueViolation, PG::ForeignKeyViolation
      break
    rescue StandardError => e
      puts e.message
      break
    end
  end

end

# PG::ForeignKeyViolation: ERROR: update or delete on table "leetcodes" violates foreign key constraint
# "fk_rails_946383d9ec" on table "leetcode_with_tags" (PG::ForeignKeyViolation
