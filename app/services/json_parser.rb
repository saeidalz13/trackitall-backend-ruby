class JsonParser
  def self.parse_body(body)
    JSON.parse(body)
  rescue JSON::ParserError => e
    Rails.logger.error e.message
    nil
  end
end
