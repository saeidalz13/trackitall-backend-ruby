class LeetcodeTag < ApplicationRecord
  has_many :leetcode_and_tags
  has_many :leetcodes, through: :leetcode_and_tags
end
