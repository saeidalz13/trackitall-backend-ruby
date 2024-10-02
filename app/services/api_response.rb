class ApiResponse
  # This is a static method in Ruby
  def self.errorJSON(error)
    { error: error }
  end

  def self.payloadJSON(payload)
    { payload: payload }
  end

  def self.fullJSON(payload, error)
    { payload: payload, error: error }
  end
end
