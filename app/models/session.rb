class Session < ApplicationRecord
  # include ULID::Rails
  # ulid :id, auto_generate: true
  
  belongs_to :user

  validates :user_id, presence: true
end
