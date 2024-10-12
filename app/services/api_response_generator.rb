# Handles the JSON response generation of this API
class ApiResponseGenerator
  # This is a static method in Ruby
  def self.error_json(error)
    { error: }
  end

  def self.payload_json(payload)
    { payload: }
  end

  def self.full_json(payload, error)
    { payload:, error: }
  end
end
