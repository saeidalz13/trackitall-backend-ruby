class UsersController < ApplicationController
  # Body Parameters: If a parameter is present in the request body, it will take precedence over query parameters and URL parameters.
  # Query Parameters: If the same parameter name exists in the query string, it will be available next.
  # URL Parameters: Finally, URL parameters will be accessible if they have not been overshadowed by body or query parameters.

  def signup
    begin
      user_params = JSON.parse(request.body.read)
      user = User.new(email: user_params["email"], password: BCrypt::Password.create(user_params["password"]))

      puts user.inspect

      if user.save
        render json: ApiResponse.new(payload: { id: user.id }).to_h, status: :created
      else
        render json: ApiResponse.new(error: "could not process request").to_h, status: :unprocessable_entity
      end

    rescue JSON::ParserError
      render json: ApiResponse.new(error: "Invalid JSON format").to_h, status: :bad_request

    rescue StandardError => e
      render json: ApiResponse.new(error: e.message).to_h, status: :service_unavailable
    end
  end

  def login
    begin
      user_params = JSON.parse(request.body.read)
      user = User.find_by(email: user_params["email"])

      if user == nil
        render json: ApiResponse.new(error: "No user with this email").to_h, status: :unauthorized
        return
      end

      if !BCrypt::Password.new(user.password).is_password?(user_params["password"])
        render json: ApiResponse.new(error: "Wrong password").to_h, status: :unauthorized
        return
      end

      render json: ApiResponse.new(payload: { id: user.id }), status: :ok

    rescue JSON::ParserError
      render json: ApiResponse.new(error: "Invalid JSON format").to_h, status: :bad_request

    rescue StandardError => e
      render json: ApiResponse.new(error: e.message).to_h, status: :service_unavailable

    end
  end
end
