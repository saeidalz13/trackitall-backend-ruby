class ApplicationController < ActionController::API
  include ActionController::Cookies

  def check_session_cookie
    session_id = extract_session_id_from_cookie(cookies.signed[:trackitall_session_id])

    if session_id.nil?
      render status: :unauthorized
      return
    end

    if get_valid_session(session_id).nil?
      render status: :unauthorized
      return nil
    end
  end

  protected

  def extract_session_id_from_cookie(session_cookie)
    unless session_cookie
      return nil
    end

    session_id, cookie_signature = session_cookie.split('.', 2)
    encKey = ActiveSupport::KeyGenerator.new(ENV["COOKIE_ENCRYPTION_SECRET"]).generate_key(ENV["COOKIE_ENCRYPTION_SALT"], 32)
    encryptor = ActiveSupport::MessageEncryptor.new(encKey)

    begin
      decrypted_hashed_session_id = encryptor.decrypt_and_verify(cookie_signature)
      expected_hashed_session_id = Digest::SHA256.hexdigest(session_id)
      
      # Verify the integrity of the session_id by comparing hashes
      if decrypted_hashed_session_id != expected_hashed_session_id
        puts "Session has been tampered with!"
        return nil
      end

      return session_id
    
    rescue ActiveSupport::MessageEncryptor::InvalidMessage => e
      puts e.message
      return nil
    end
  end

  def get_valid_session(session_id) 
    session = Session.find(session_id)
    if session.nil?
      return nil
    end

    if session.expires_at > Time.new
      session.destroy
      return nil
    end

    return session
  end

  def get_user_id_from_cookie(session_cookie)
    session_id = extract_session_id_from_cookie(session_cookie)
    if session_id.nil?
      return nil
    end

    valid_session = get_valid_session(session_id)
    if valid_session.nil?
      return nil
    end

    return valid_session.user_id
  end
  
  def create_cookie_signature(session_id)
    begin
      hashed_session_id = Digest::SHA256.hexdigest(session_id)
      encKey = ActiveSupport::KeyGenerator.new(ENV["COOKIE_ENCRYPTION_SECRET"]).generate_key(ENV["COOKIE_ENCRYPTION_SALT"], 32)
      encryptor = ActiveSupport::MessageEncryptor.new(encKey)
      return encryptor.encrypt_and_sign(hashed_session_id)

    rescue ActiveSupport::MessageEncryptor::InvalidMessage => e
      puts e.message
      return nil

    rescue StandardError => e
      puts e.message
      return nil
    end
  end
end
