class JobController < ApplicationController
  # before_action :check_session_cookie, only: [:index, :show, :new, :update, :destroy]

  def index
    user_id = get_user_id_from_cookie(cookies[:trackitall_session_id])
    if user_id.nil?
      render status: :unauthorized
      return
    end

    begin
      limit = params[:limit].to_i > 0 ? params[:limit].to_i : 10
      offset = params[:offset].to_i >= 0 ? params[:offset].to_i : 0

    rescue ArgumentError => e
      Rails.logger.error("Invalid offset and limit: #{e.message}")
      render json: ApiResponse.errorJSON("non-integer offset or limit"), status: :bad_request
      return
    end

    begin
      jobs = Job.where(user_id: user_id).limit(limit).offset(offset)
      job_count = Job.where(user_id: user_id).count
      render json: ApiResponse.payloadJSON({ jobs: jobs, job_count: job_count })

    rescue StandardError => e
      Rails.logger.error("Unexpected error in fetching jobs: #{e.message}")
      render json: ApiResponse.errorJSON("non-integer offset or limit"), status: :service_unavailable
    end
  end

  def show
    puts("somethings")
  end


  def new
  end


  def update
  end

  def destroy
  end
end
