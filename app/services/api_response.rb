class ApiResponse
  attr_accessor :payload, :error

  def initialize(payload: nil, error: nil)
    @payload = payload
    @error = error
  end

  def to_h
    {
      payload: @payload,
      error: @error
    }.compact  # Remove nil values
  end
end
