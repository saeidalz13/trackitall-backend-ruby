class AiController < ApplicationController
  include ActionController::Live
  OPENAI_CHAT_COMP_URI = URI('https://api.openai.com/v1/chat/completions')

  def get_ai_insight
    # SSE between client and server
    response.headers['Content-Type'] = 'text/event-stream'
    sse = SSE.new(response.stream, retry: 300, event: 'event-name')

    user_id = get_user_id_from_cookie(cookies[:trackitall_session_id])
    if user_id.nil?
      sse.write({ error: 'Unauthorized' }, event: 'error')
      sse.close
      return
    end

    job = Job.where(id: params[:job_id], user_id:).first
    if job.nil?
      sse.write({ error: 'Job not found' }, event: 'error')
      sse.close
      return
    end

    if job.description.nil?
      sse.write({ error: 'Job description is missing' }, event: 'error')
      sse.close
      return
    end

    Net::HTTP.start(
      OPENAI_CHAT_COMP_URI.host, OPENAI_CHAT_COMP_URI.port,
      use_ssl: (OPENAI_CHAT_COMP_URI.scheme = 'https')
    ) do |http|
      req = Net::HTTP::Post.new(OPENAI_CHAT_COMP_URI.to_s)

      # SSE between server and Open AI
      req['Content-Type'] = 'application/json'
      req['Authorization'] = "Bearer #{ENV['OPENAI_KEY']}"
      req['Accept'] = 'text/event-stream'

      req.body = {
        model: 'gpt-4o',
        messages: [
          {
            role: 'system',
            content: create_ai_insight_content(job)
          }
        ],
        stream: true
      }.to_json

      http.request(req) do |response|
        response.read_body do |chunk|
          # ! Each chunk can have multiple lines
          chunk.split("\n").each do |line|
            next if line.strip.empty?

            line = line.gsub('data: ', '').strip

            begin
              # Specified by OpenAI docs
              # https://platform.openai.com/docs/api-reference/chat/create
              if line == '[DONE]'
                sse.write(line, event: 'message')
                break
              end

              data = JSON.parse(line)
              content = data['choices'][0]['delta']['content']
              next if content.nil?

              sse.write(content, event: 'message')
            rescue JSON::ParserError => e
              puts e.message
              next
            end
          end
        end
      end
    end
  rescue StandardError => e
    Rails.logger.error(e.message)
    sse.write({ error: 'Unknown error server' }, event: 'error')
  ensure
    sse.close
  end

  protected

  def create_ai_insight_content(job)
    <<~CONTENT
      Based on the job description provided below,
      please give me information about #{job.company_name} company, their mission and useful insight you might have to help me succeed in my interview with them.
      I have an interview with them for #{job.position} position.
      KEEP YOUR ANSWER LESS THAN 10000 characters please.

      #{job.description}
    CONTENT
  end
end
