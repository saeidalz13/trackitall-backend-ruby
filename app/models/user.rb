class User < ApplicationRecord
  include ULID::Rails
  ulid :id, auto_generate: true

  # defines `created_at` method which extract timestamp value from id column.
  # This way you don't need physical `created_at` column.
  # ulid_extract_timestamp :id, :created_at
end
