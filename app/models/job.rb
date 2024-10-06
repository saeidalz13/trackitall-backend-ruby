class Job < ApplicationRecord
  belongs_to :user

  validates :position, presence: true
  validates :company_name, presence: true
end
