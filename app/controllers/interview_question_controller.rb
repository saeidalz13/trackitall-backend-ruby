class InterviewQuestionController < ApplicationController
  def show
    user_id = get_user_id_from_cookie(cookies[:trackitall_session_id])
    raw_data = InterviewQuestion.where('user_id = ? AND job_id = ?', user_id, params[:job_id])

    job_interview_questions = ApiSerializer.serialize_interview_questions(raw_data)
    render json: ApiResponseGenerator.payload_json(job_interview_questions), status: :ok
  end

  def update
    user_id = get_user_id_from_cookie(cookies[:trackitall_session_id])
    return render status: :unauthorized if user_id.nil?

    iq = InterviewQuestion.find_by(id: params[:id])
    return render status: :not_found if iq.nil?

    iq.update!(JSON.parse(request.body.read))
    render status: :ok
  rescue JSON::ParserError => e
    Rails.logger.info e.message
    render json: ApiResponseGenerator.error_json('Invalid JSON format'), status: :bad_request
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.info e.message
    render status: :bad_request
  rescue ActiveRecord::RecordNotFound => e
    Rails.logger.info e.message
    render json: ApiResponseGenerator.error_json(e.message), status: :not_found
  end
end
