# Controller for all users and auth interactions
class UsersController < ApplicationController
  def send_auth_server
    # oauth2_json_path = ENV["GOOGLE_OAUTH2_INFO_JSON"]
    # outh2_data = JSON.parse(oauth2_json_path)
    # web_data = outh2_data["web"]
    redirect_uri = if Rails.env.production?
                     ENV['OAUTH_REDIRECT_URI_PROD']
                   else
                     ENV['OAUTH_REDIRECT_URI']
                   end

    auth_server_uri = <<~URI
      #{ENV['OAUTH_GOOGLE_AUTH_URI']}?
      client_id=#{ENV['OAUTH_GOOGLE_CLIENT_ID']}&
      redirect_uri=#{redirect_uri}&
      response_type=code&
      state=#{SecureRandom.hex(16)}&
      scope=email
    URI

    render json: ApiResponseGenerator.payload_json({ auth_server_uri: }), status: :ok
  rescue StandardError => e
    render json: ApiResponseGenerator.error_json(e.message), status: :service_unavailable
  end

  # This method handles the Google OAuth2 redirect.
  # It exchanges the authorization code for an access token.
  #
  # @return [Hash] The parsed response from the token exchange, including the access token and ID token.
  # @raise [StandardError] Raises an error if the token exchange fails.
  #
  # The flow is as follows:
  # 1. Extract the authorization code from the query parameters.
  # 2. Prepare a POST request to the token endpoint of the Google API.
  # 3. On success, parse the response for the access token and ID token.
  # 4. Verify the JWT signature using Google's public keys.
  #
  # ** OAUTH_TOKEN_EXHANGE_URI:
  # Response will have the fields below:
  # - access_token
  # - expires_in  (seconds)
  # - scope
  # - token_type
  # - id_token
  #
  # ** OAUTH_GOOGLE_CERTS_URI:
  # Response is a json with the name of 'keys'. Then keys value is an array of key objects
  # each key schema:
  #   - n: modulus for RSA
  #   - e: exponent for RSA
  #   - kid
  #   - alg
  #   ...
  def google_redirect_oauth2
    frontend_uri = if Rails.env.production?
                     ENV['FRONTEND_URI_PROD']
                   else
                     ENV['FRONTEND_URI']
                   end

    # Exchange token with the received auth code
    token_exchange_uri = URI(ENV['OAUTH_GOOGLE_TOKEN_EXHANGE_URI'])

    redirect_uri = if Rails.env.production?
                     ENV['OAUTH_REDIRECT_URI_PROD']
                   else
                     ENV['OAUTH_REDIRECT_URI']
                   end
    token_exchange_uri.query = URI.encode_www_form(
      {
        code: params['code'],
        client_id: ENV['OAUTH_GOOGLE_CLIENT_ID'],
        client_secret: ENV['OAUTH_CLIENT_SECRET'],
        redirect_uri:,
        grant_type: 'authorization_code'
      }
    )
    resp = Net::HTTP.start(token_exchange_uri.host, token_exchange_uri.port,
                           use_ssl: (token_exchange_uri.scheme == 'https')) do |http|
      req = Net::HTTP::Post.new(token_exchange_uri.to_s)
      req['Content-Type'] = 'application/x-www-form-urlencoded'
      http.request(req)
    end
    auth_body = JSON.parse(resp.body)

    # Receiving the certs (encryption keys and algs for decrypting the id_token JWT)
    certs_uri = URI(ENV['OAUTH_GOOGLE_CERTS_URI'])
    certs_resp = Net::HTTP.start(certs_uri.host, certs_uri.port, use_ssl: (certs_uri.scheme == 'https')) do |http|
      req = Net::HTTP::Get.new(certs_uri.to_s)
      req['Content-Type'] = 'application/json'
      http.request(req)
    end
    certs_body = JSON.parse(certs_resp.body)

    # Decode without encryption to get the key from its header
    user_jwt = JWT.decode auth_body['id_token'], nil, false
    # user_jwt.second is the Header segment
    kid = user_jwt.second['kid']
    key_data = certs_body['keys'].find { |key| key['kid'] == kid }

    # Decoding into raw binary
    modulus = Base64.urlsafe_decode64(key_data['n'])
    exponent = Base64.urlsafe_decode64(key_data['e'])

    # onstruct ASN.1 DER-encoded public key from n and e
    asn1 = OpenSSL::ASN1::Sequence([
                                     OpenSSL::ASN1::Integer.new(OpenSSL::BN.new(modulus, 2)),
                                     OpenSSL::ASN1::Integer.new(OpenSSL::BN.new(exponent, 2))
                                   ])
    # Create the RSA public key using ASN.1 DER encoding
    rsa_public = OpenSSL::PKey::RSA.new(asn1.to_der)

    # Fetching email
    decoded_token = JWT.decode(auth_body['id_token'], rsa_public, true, { algorithm: 'RS256' })
    email = decoded_token.first['email']

    ActiveRecord::Base.transaction do
      user = User.find_by(email:)
      if user.nil?
        user = User.create!(
          id: ULID.generate,
          email:,
          password: BCrypt::Password.create(SecureRandom.hex(20))
        )
      end

      Session.where(user_id: user.id).delete_all

      session = Session.create!(id: ULID.generate, user_id: user.id, issued_at: Time.new.to_i,
                                expires_at: Time.new.to_i + 86_400)
      cookie_signature = create_cookie_signature(session.id)
      raise StandardError, 'Failed to create cookie signature' if cookie_signature.nil?

      response.set_header('Set-Cookie', generate_session_id_cookie(session.id, cookie_signature))
    end

    redirect_to "#{frontend_uri}/profile?auth=true", allow_other_host: true
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error "Invalid Record Error: #{e.message}"
    redirect_to "#{frontend_uri}?oauth2_error=failed-to-create-user", allow_other_host: true
  rescue StandardError => e
    Rails.logger.error "Standard Error: #{e.message}"
    redirect_to "#{frontend_uri}?oauth2_error=something-went-wrong", allow_other_host: true
  end

  def signup
    frontend_uri = if Rails.env.production?
                     ENV['FRONTEND_URI_PROD']
                   else
                     ENV['FRONTEND_URI']
                   end
    user_params = JSON.parse(request.body.read)

    # ! (bang) throws an exception if something went wrong
    ActiveRecord::Base.transaction do
      user = User.create!(id: ULID.generate, email: user_params['email'],
                          password: BCrypt::Password.create(user_params['password']))

      Session.where(user_id: user.id).delete_all
      session = Session.create!(id: ULID.generate, user_id: user.id, issued_at: Time.new.to_i,
                                expires_at: Time.new.to_i + 86_400)

      cookie_signature = create_cookie_signature(session.id)
      raise StandardError, 'Failed to create cookie signature' if cookie_signature.nil?

      response.set_header('Set-Cookie', generate_session_id_cookie(session.id, cookie_signature))
      redirect_to "#{frontend_uri}/profile?auth=true", allow_other_host: true
    end
  rescue JSON::ParserError => e
    puts e.message
    render json: ApiResponseGenerator.error_json('Invalid JSON format'), status: :bad_request

    # This is thrown by `create!`
  rescue ActiveRecord::RecordInvalid => e
    puts e.message
    render json: ApiResponseGenerator.error_json(e.message), status: :bad_request
  rescue StandardError => e
    puts e.message
    render json: ApiResponseGenerator.error_json(e.message), status: :service_unavailable
  end

  def login
    user_params = JSON.parse(request.body.read)
    user = User.find_by!(user_params['email'])

    unless BCrypt::Password.new(user.password).is_password?(user_params['password'])
      render json: ApiResponseGenerator.error_json('Wrong username or password'), status: :unauthorized
      return
    end

    Session.where(user_id: user.id).delete_all
    session = Session.create!(id: ULID.generate, user_id: user.id, issued_at: Time.new.to_i,
                              expires_at: Time.new.to_i + 86_400)
    cookie_signature = create_cookie_signature(session.id)
    raise StandardError, 'Failed to create cookie signature' if cookie_signature.nil?

    response.set_header('Set-Cookie', generate_session_id_cookie(session.id, cookie_signature))
    redirect_to "#{ENV['FRONTEND_URI']}/profile?auth=true", allow_other_host: true
  rescue JSON::ParserError
    render json: ApiResponseGenerator.error_json('Invalid JSON format'), status: :bad_request
  rescue ActiveRecord::RecordNotFound => e
    render json: ApiResponseGenerator.error_json("Wrong username or password, #{e.message}"), status: :unauthorized
  rescue StandardError => e
    render json: ApiResponseGenerator.error_json(e.message), status: :service_unavailable
  end

  def signout
    session_id = extract_session_id_from_cookie(cookies[:trackitall_session_id])
    raise ActionController::BadRequest, 'Session ID is missing or invalid' if session_id.nil?

    Session.find(session_id).destroy!

    response.set_header('Set-Cookie', 'trackitall_session_id=nil; HttpOnly; SameSite=None; Secure; Max-Age=-1')
    render status: :no_content
  rescue ActionController::BadRequest => e
    Rails.logger.error(e.message)
    render status: :bad_request
  rescue ActiveRecord::RecordNotFound => e
    render json: ApiResponseGenerator.error_json(e.message), status: :not_found
  rescue StandardError => e
    puts e.message
    render json: ApiResponseGenerator.error_json(e.message), status: :service_unavailable
  end

  def destroy
    user = User.find_by!(id: params[:id])
    user.destroy!
    render status: :no_content
  rescue ActiveRecord::RecordNotFound => e
    render json: ApiResponseGenerator.error_json(e.message), status: :not_found
  rescue ActiveRecord::RecordNotDestroyed => e
    render json: ApiResponseGenerator.error_json(e.message), status: :bad_request
  rescue StandardError => e
    render json: ApiResponseGenerator.error_json(e.message), status: :service_unavailable
  end

  def session_valid?
    user_id = get_user_id_from_cookie(cookies[:trackitall_session_id])
    return render status: :unauthorized if user_id.nil?

    render status: :ok
  end
end
