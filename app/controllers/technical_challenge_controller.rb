class TechnicalChallengeController < ApplicationController
  def index
    user_id = get_user_id_from_cookie(cookies[:trackitall_session_id])
    return render status: :unauthorized if user_id.nil?

    tech_challenges = TechnicalChallenge
                      .where('user_id = ? AND job_id = ?', user_id, params[:job_id])
                      .select(:id, :question)
    return render status: :not_found if tech_challenges.nil?

    render json: ApiResponseGenerator.payload_json({ tech_challenges: }), status: :ok
  rescue ActiveRecord::RecordNotFound => e
    Rails.logger.error e.message
    render status: :not_found
  rescue StandardError => e
    Rails.logger.error e.message
    render status: :service_unavailable
  end
end
