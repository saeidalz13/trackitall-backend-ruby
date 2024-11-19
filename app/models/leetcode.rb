class Leetcode < ApplicationRecord
  has_many :leetcode_and_tags
  has_many :leetcode_tags, through: :leetcode_and_tags
end
