class JobController < ApplicationController
  before_action :check_session_cookie, only: %i[destroy update]

  def index
    user_id = get_user_id_from_cookie(cookies[:trackitall_session_id])
    if user_id.nil?
      render status: :unauthorized
      return
    end

    begin
      limit = params[:limit].to_i.positive? ? params[:limit].to_i : 10
      offset = params[:offset].to_i >= 0 ? params[:offset].to_i : 0
    rescue ArgumentError => e
      Rails.logger.error("Invalid offset and limit: #{e.message}")
      render json: ApiResponseGenerator.error_json('non-integer offset or limit'), status: :bad_request
      return
    end

    begin
      jobs = Job.where(user_id:).limit(limit).offset(offset)
      job_count = Job.where(user_id:).count
      render json: ApiResponseGenerator.payload_json({ jobs:, job_count: })
    rescue StandardError => e
      Rails.logger.error("Unexpected error in fetching jobs: #{e.message}")
      render json: ApiResponseGenerator.error_json('non-integer offset or limit'), status: :service_unavailable
    end
  end

  def show
    job = Job.find_by!(id: params[:id])
    render json: ApiResponseGenerator.payload_json(job), status: :ok
  rescue ActiveRecord::RecordNotFound => e
    render json: ApiResponseGenerator.error_json(e.message), status: :not_found
  rescue StandardError => e
    Rails.logger.error("Unexpected error in fetching job #{params[:id]}: #{e.message}")
    render json: ApiResponseGenerator.error_json(e.message), status: :service_unavailable
  end

  def new
    user_id = get_user_id_from_cookie(cookies[:trackitall_session_id])
    if user_id.nil?
      render status: :unauthorized
      return
    end

    job = JsonParser.parse_body(request.body.read)
    puts job.inspect
    if job.nil?
      render json: ApiResponseGenerator.error_json('invalid body'), status: :bad_request
      return
    end

    ActiveRecord::Base.transaction do
      created_job = Job.create!(
        id: ULID.generate,
        user_id:,
        position: job['position'],
        company_name: job['company_name'],
        applied_date: job['applied_date'],
        link: job['link'],
        description: ['description'],
        ai_insight: nil,
        resume_path: nil
      )

      InterviewQuestion.add_default_questions(user_id, created_job.id)

      render json: ApiResponseGenerator.payload_json(
        {
          id: created_job.id,
          applied_date: created_job.applied_date
        }
      ), status: :created
    rescue ActiveRecord::RecordInvalid => e
      Rails.logger.error(e.message)
      render json: ApiResponseGenerator.error_json(e.message), status: :bad_request
    rescue StandardError => e
      Rails.logger.error(e.message)
      render json: ApiResponseGenerator.error_json(e.message), status: :service_unavailable
    end
  end

  def update
    # job = Job.find_by!(id: params[:job_ulid])
    render status: :ok
  rescue ActiveRecord::RecordNotFound => e
    render json: ApiResponseGenerator.error_json(e.message), status: :not_found
  end

  def destroy
    job = Job.find_by!(id: params[:id])
    job.destroy!
    render status: :no_content
  rescue ActiveRecord::RecordNotFound => e
    render json: ApiResponseGenerator.error_json(e.message), status: :not_found
  rescue ActiveRecord::RecordNotDestroyed => e
    render json: ApiResponseGenerator.error_json(e.message), status: :bad_request
  rescue StandardError => e
    render json: ApiResponseGenerator.error_json(e.message), status: :service_unavailable
  end
end
