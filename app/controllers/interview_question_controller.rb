class InterviewQuestionController < ApplicationController
  def show
    user_id = get_user_id_from_cookie(cookies[:trackitall_session_id])
    raw_data = InterviewQuestion.where('user_id = ? AND job_id = ?', user_id, params[:job_id])

    job_interview_questions = ApiSerializer.serialize_interview_questions(raw_data)
    render json: ApiResponseGenerator.payload_json(job_interview_questions), status: :ok
  end
end
