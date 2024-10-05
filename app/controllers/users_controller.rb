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
        + "&scope=email"

      render json: ApiResponse.payloadJSON({ auth_server_uri: auth_server_uri }), status: :ok

    rescue StandardError => e
      render json: ApiResponse.errorJSON(e.message), status: :service_unavailable
    end
  end

  """
  The endpoint for Google OAuth2 callback. it comes back
  with state, code, scope, etc. in the query parameters.
  `code` is authorization code that we want to be able to
  get the access_token.

  after fetching `code` from query params, we send a POST
  request to token endpoint of google API. If success, it
  gives us back a json containing the access_token, along with
  id_token which is a JWT of user information

  We want to verify the signature of JWT. we get the modulus and exponent
  from google/certs endpoint. 
  1. From JWT header, we identify which key was used
  2. Then we select the n and e of that key
  3. We create a public key using the alg provided (RSA256)
  4. Then using jwt library, we verify the signature and 
  get user information from the payload

  """
  def google_redirect_oauth2
    begin
      tokenExchangeUri = URI(ENV["OAUTH_TOKEN_EXHANGE_URI"])
      tokenExchangeUri.query = URI.encode_www_form({
        code: params["code"],
        client_id: ENV["OAUTH_CLIENT_ID"],
        client_secret: ENV["OAUTH_CLIENT_SECRET"],
        redirect_uri: ENV["OAUTH_REDIRECT_URI"],
        grant_type: "authorization_code"
      })

      """
      This response will have the schema below:
        - access_token 
        - expires_in  (seconds)
        - scope
        - token_type
        - id_token
      """
      resp = Net::HTTP.start(tokenExchangeUri.host, tokenExchangeUri.port, use_ssl: (tokenExchangeUri.scheme == "https")) do |http|
        req = Net::HTTP::Post.new(tokenExchangeUri.to_s)
        req["Content-Type"] = "application/x-www-form-urlencoded"
        http.request(req)
      end
      authBody = JSON.parse(resp.body)

      certsUri = URI(ENV["OAUTH_CERTS_URI"])
      """
      Response is a json with the name of 'keys'. Then keys value is an array of key objects
      each key schema:
        - n: modulus for RSA
        - e: exponent for RSA
        - kid
        - alg
        ...
      """
      certsResp = Net::HTTP.start(certsUri.host, certsUri.port, use_ssl: (certsUri.scheme == "https")) do | http |
        req = Net::HTTP::Get.new(certsUri.to_s)
        req["Content-Type"] = "application/json"
        http.request(req)
      end
      certsBody = JSON.parse(certsResp.body)

      # Decode without encryption to get the key from its header
      userJWT = JWT.decode authBody["id_token"], nil, false
      # userJWT.second is the Header segment
      kid = userJWT.second["kid"]
      key_data = certsBody["keys"].find { |key| key["kid"] == kid }

      # Decoding into raw binary
      modulus = Base64.urlsafe_decode64(key_data["n"])
      exponent = Base64.urlsafe_decode64(key_data["e"])

      # onstruct ASN.1 DER-encoded public key from n and e
      asn1 = OpenSSL::ASN1::Sequence([
        OpenSSL::ASN1::Integer.new(OpenSSL::BN.new(modulus, 2)),
        OpenSSL::ASN1::Integer.new(OpenSSL::BN.new(exponent, 2))
      ])
      # Create the RSA public key using ASN.1 DER encoding
      rsa_public = OpenSSL::PKey::RSA.new(asn1.to_der)

      # Fetching email
      decoded_token = JWT.decode(authBody["id_token"], rsa_public, true, { algorithm: 'RS256' })
      email = decoded_token.first["email"]

      ActiveRecord::Base.transaction do
        user = User.find_by(email: email)
        if user == nil
          user = User.create!(email: email, password: BCrypt::Password.create(SecureRandom.hex(20)))
        end
  
        session = Session.create!(id: ULID.generate, user_id: user.id, issued_at: Time.new.to_i, expires_at: Time.new.to_i + 86400)
        cookie_signature = create_cookie_signature(session.id)
        if cookie_signature.nil?
          raise StandardError.new("Failed to create cookie signature")
        end
  
        response.set_header("Set-Cookie", "trackitall_session_id=#{session.id}.#{cookie_signature}; HttpOnly; SameSite=None; Secure; Expires=86400")
      end

      redirect_to "#{ENV["FRONTEND_URI"]}/profile?auth=true", allow_other_host: true

    rescue ActiveRecord::RecordInvalid => ri
      puts "Invalid Record Error: #{ri.message}"
      redirect_to "#{ENV["FRONTEND_URI"]}?oauth2_error=#{ri.message}", allow_other_host: true

    rescue StandardError => e
      puts "Standard Error: #{e.message}"
      redirect_to "#{ENV["FRONTEND_URI"]}?oauth2_error=#{e.message}", allow_other_host: true
    end
  end

  def signup
    begin
      user_params = JSON.parse(request.body.read)

      # ! (bang) throws an exception if something went wrong
      ActiveRecord::Base.transaction do
        user = User.create!(id: ULID.generate, email: user_params["email"], password: BCrypt::Password.create(user_params["password"]))
        session = Session.create!(id: ULID.generate, user_id: user.id, issued_at: Time.new.to_i, expires_at: Time.new.to_i + 86400)
        
        cookie_signature = create_cookie_signature(session.id)
        if cookie_signature.nil?
          raise StandardError.new("Failed to create cookie signature")
        end
  
        response.set_header("Set-Cookie", "trackitall_session_id=#{session.id}.#{cookie_signature}; HttpOnly; SameSite=None; Secure; Expires=86400")
        redirect_to "#{ENV["FRONTEND_URI"]}/profile?auth=true", allow_other_host: true
      end

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
      cookie_signature = create_cookie_signature(session.id)
      if cookie_signature.nil?
        raise StandardError.new("Failed to create cookie signature")
      end

      response.set_header("Set-Cookie", "trackitall_session_id=#{session.id}.#{cookie_signature}; HttpOnly; SameSite=None; Secure; Expires=86400")
      redirect_to "#{ENV["FRONTEND_URI"]}/profile?auth=true", allow_other_host: true

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

    rescue ActiveRecord::RecordNotFound => rnf
      render json: ApiResponse.errorJSON(rnf.message), status: :not_found

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
