class JobController < ApplicationController
  # before_action :check_session_cookie, only: %i[update]

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
      search_term = params[:search]
      jobs = Job.where(user_id:)

      if search_term.present?
        jobs = jobs.where('position ILIKE ? OR company_name ILIKE ?', "%#{search_term}%", "%#{search_term}%")
      end

      jobs = jobs.limit(limit).offset(offset)

      job_count = Job.where(user_id:)
      if search_term.present?
        job_count = job_count.where('position ILIKE ? OR company_name ILIKE ?', "%#{search_term}%",
                                    "%#{search_term}%")
      end
      job_count = job_count.count
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
        description: job['description'],
        ai_insight: nil,
        resume_path: nil
      )

      unless InterviewQuestion.add_default_questions(user_id, created_job.id)
        raise ActiveRecord::Rollback, 'Failed to add questions'
      end

      render json: ApiResponseGenerator.payload_json(
        {
          id: created_job.id,
          applied_date: created_job.applied_date
        }
      ), status: :created
    end
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error(e.message)
    render json: ApiResponseGenerator.error_json(e.message), status: :bad_request
  rescue StandardError => e
    Rails.logger.error(e.message)
    render json: ApiResponseGenerator.error_json(e.message), status: :service_unavailable
  end

  def update
    user_id = get_user_id_from_cookie(cookies[:trackitall_session_id])
    if user_id.nil?
      render status: :unauthorized
      return
    end

    job = Job.where('id = ? AND user_id = ?', params[:id], user_id).first
    if job.nil?
      render status: :not_found
      return
    end

    req_body = JSON.parse(request.body.read)
    job.update!(req_body)

    render status: :ok
  rescue JSON::ParserError => e
    puts e.message
    render json: ApiResponseGenerator.error_json('Invalid JSON format'), status: :bad_request
  rescue ActiveRecord::RecordInvalid => e
    puts e.message
    render status: :bad_request
  rescue ActiveRecord::RecordNotFound => e
    render json: ApiResponseGenerator.error_json(e.message), status: :not_found
  end

  def destroy
    user_id = get_user_id_from_cookie(cookies[:trackitall_session_id])
    if user_id.nil?
      render status: :unauthorized
      return
    end

    job = Job.where('id = ? AND user_id = ?', params[:id], user_id).first
    if job.nil?
      render status: :not_found
      return
    end

    job.destroy!
    render status: :no_content
  rescue ActiveRecord::RecordNotDestroyed => e
    render json: ApiResponseGenerator.error_json(e.message), status: :bad_request
  rescue StandardError => e
    render json: ApiResponseGenerator.error_json(e.message), status: :service_unavailable
  end
end
