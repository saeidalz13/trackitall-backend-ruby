class User < ApplicationRecord
  has_one :session, dependent: :destroy
  has_many :jobs, dependent: :destroy

  validates :email, presence: true, uniqueness: true
  validates :password, presence: true
end
