class ApplicationController < ActionController::API
  include ActionController::Cookies

  protected

  # Middleware for authentication
  def check_session_cookie
    session_id = extract_session_id_from_cookie(cookies.signed[:trackitall_session_id])

    if session_id.nil?
      render status: :unauthorized
      nil
    end

    return unless get_valid_session(session_id).nil?

    render status: :unauthorized
    nil
  end

  def extract_session_id_from_cookie(session_cookie)
    return nil unless session_cookie

    session_id, cookie_signature = session_cookie.strip.split('.', 2)
    cookie_signature = cookie_signature.gsub(' ', '+')

    enc_key = ActiveSupport::KeyGenerator.new(ENV['COOKIE_ENCRYPTION_SECRET']).generate_key(
      ENV['COOKIE_ENCRYPTION_SALT'], 32
    )
    encryptor = ActiveSupport::MessageEncryptor.new(enc_key)

    begin
      decrypted_hashed_session_id = encryptor.decrypt_and_verify(cookie_signature)
      expected_hashed_session_id = Digest::SHA256.hexdigest(session_id)

      # Verify the integrity of the session_id by comparing hashes
      if decrypted_hashed_session_id != expected_hashed_session_id
        puts 'Session has been tampered with!'
        return nil
      end

      session_id
    rescue ActiveSupport::MessageEncryptor::InvalidMessage => e
      puts "MessageEncryptor Invalid Message: #{e.message}"
      nil
    rescue StandardError => e
      puts e.message
    end
  end

  def get_valid_session(session_id)
    session = Session.find(session_id)
    return nil if session.nil?

    if session.expires_at < Time.new.to_i
      session.destroy
      return nil
    end

    session
  end

  def get_user_id_from_cookie(session_cookie)
    session_id = extract_session_id_from_cookie(session_cookie)
    return nil if session_id.nil?

    valid_session = get_valid_session(session_id)
    return nil if valid_session.nil?

    valid_session.user_id
  end

  # Create a digital signature cookie to add a layer
  # of security. It's then attached to the cookie
  def create_cookie_signature(cookie_value)
    hashed_cookie_value = Digest::SHA256.hexdigest(cookie_value)
    enc_key = ActiveSupport::KeyGenerator.new(ENV['COOKIE_ENCRYPTION_SECRET']).generate_key(
      ENV['COOKIE_ENCRYPTION_SALT'], 32
    )
    encryptor = ActiveSupport::MessageEncryptor.new(enc_key)
    encryptor.encrypt_and_sign(hashed_cookie_value)
  rescue ActiveSupport::MessageEncryptor::InvalidMessage => e
    puts e.message
    nil
  rescue StandardError => e
    puts e.message
    nil
  end

  def generate_session_id_cookie(session_id, cookie_signature)
    "trackitall_session_id=#{session_id}.#{cookie_signature}; HttpOnly; SameSite=None; Secure; Max-Age=86400"
  end
end
