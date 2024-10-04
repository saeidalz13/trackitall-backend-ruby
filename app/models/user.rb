class User < ApplicationRecord
  # include ULID::Rails
  # ulid :id, auto_generate: true

  has_one :session, dependent: :destroy

  validates :email, presence: true, uniqueness: true
  validates :password, presence: true
end
