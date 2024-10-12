class JsonParser
  def self.parse_body(body)
    JSON.parse(body)
  rescue JSON::ParserError => e
    puts e.message
    nil
  end
end
