# frozen_string_literal: true

# Model for session cookies
class Session < ApplicationRecord
  belongs_to :user

  validates :user_id, presence: true

  def self.clean_up_session_ids
    Session.where('expires_at < ?', Time.new.to_i).delete_all
    puts 'Periodic session id clean-up executed'
  end
end
