class UsersController < ApplicationController
  def send_auth_server
    begin
      # oauth2_json_path = ENV["GOOGLE_OAUTH2_INFO_JSON"]
      # outh2_data = JSON.parse(oauth2_json_path)
      # web_data = outh2_data["web"]

      auth_server_uri = ENV["OAUTH_AUTH_URI"] + "?" \
        + "client_id=#{ENV["OAUTH_CLIENT_ID"]}" \
        + "&redirect_uri=#{ENV["OAUTH_REDIRECT_URI"]}" \
        + "&response_type=code" \
        + "&state=#{SecureRandom.hex(16)}" \
        + "&scope=profile"

      render json: ApiResponse.payloadJSON({ auth_server_uri: auth_server_uri }), status: :ok

    rescue StandardError => e
      render json: ApiResponse.errorJSON(e.message), status: :service_unavailable
    end
  end

  def google_redirect_oauth2
    puts params.inspect
    # state
    # code
    # scope
    # controller
    # action

    # TODO: exchange the code
    redirect_to "#{ENV["FRONTEND_URI"]}?state=#{params["state"]}&code=#{params["code"]}", allow_other_host: true
  end

  def signup
    begin
      user_params = JSON.parse(request.body.read)

      # ! (bang) throws an exception if something went wrong
      ActiveRecord::Base.transaction do
        user = User.create!(id: ULID.generate, email: user_params["email"], password: BCrypt::Password.create(user_params["password"]))
        session = Session.create!(id: ULID.generate, user_id: user.id, issued_at: Time.new.to_i, expires_at: Time.new.to_i + 86400)
        
        response.set_header("Set-Cookie", "trackitall_session_id=#{session.id}; HttpOnly; SameSite=None; Secure; Expires=86400")

        render json: ApiResponse.payloadJSON({ user_id: user.id, email: user.email }), status: :created
      end

      # TODO: cryptographically signing the cookie
      # 1. hash the cookie
      # 2. sign the cookie with a secret (symmetric)

    rescue JSON::ParserError => pe
      puts pe.message
      render json: ApiResponse.errorJSON("Invalid JSON format"), status: :bad_request

      # This is thrown by `create!`
    rescue ActiveRecord::RecordInvalid => ri
      puts ri.message
      render json: ApiResponse.errorJSON(ri.message), status: :bad_request

    rescue StandardError => e
      puts e.message
      render json: ApiResponse.errorJSON(e.message), status: :service_unavailable
    end
  end

  def login
    begin
      Rails.logger.info "#{request.headers["Content-Type"]}"

      user_params = JSON.parse(request.body.read)
      user = User.find_by!(email: user_params["email"])

      if !BCrypt::Password.new(user.password).is_password?(user_params["password"])
        render json: ApiResponse.errorJSON("Wrong password"), status: :unauthorized
        return
      end

      session = Session.create!(id: ULID.generate, user_id: user.id, issued_at: Time.new.to_i, expires_at: Time.new.to_i + 86400)
      response.set_header("Set-Cookie", "trackitall_session_id=#{session.id}; HttpOnly; SameSite=None; Secure; Expires=86400")

      render json: ApiResponse.payloadJSON({ id: user.id }), status: :ok

    rescue JSON::ParserError
      render json: ApiResponse.errorJSON("Invalid JSON format"), status: :bad_request

    rescue ActiveRecord::RecordNotFound => rnf
      render json: ApiResponse.errorJSON(rnf.message), status: :not_found

    rescue StandardError => e
      render json: ApiResponse.errorJSON(e.message), status: :service_unavailable
    end
  end


  def signout
    begin
      session = Session.find_by!(id: cookies[:trackitall_session_id])
      session.destroy!
      render status: :no_content

    rescue StandardError => e
      render json: ApiResponse.errorJSON(e.message), status: :service_unavailable
    end
  end

  def destroy
    begin
      user = User.find_by!(id: params[:id])
      user.destroy!
      render status: :no_content

    rescue ActiveRecord::RecordNotFound => rnf
      render json: ApiResponse.errorJSON(rnf.message), status: :not_found

    rescue ActiveRecord::RecordNotDestroyed => rnd
      render json: ApiResponse.errorJSON(rnd.message), status: :bad_request

    rescue StandardError => e
      render json: ApiResponse.errorJSON(e.message), status: :service_unavailable
    end
  end
end
