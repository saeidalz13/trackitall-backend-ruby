class FsController < ApplicationController
  def new
    user_id = get_user_id_from_cookie(cookies[:trackitall_session_id])
    return render status: :unauthorized if user_id.nil?

    job_ulid = params[:job_ulid]
    job = Job.find(job_ulid)
    return render status: :not_found if job.nil?

    file = params[:file]
    return render status: :bad_request unless file.present?

    file_dir = File.join(ENV['FILE_STORAGE_PATH'], user_id)
    Dir.mkdir file_dir unless Dir.exist? file_dir

    file_path = File.join(file_dir, "#{job_ulid}_#{file.original_filename}")
    File.open(file_path, 'wb') do |f|
      f.write(file.read)
    end

    job.update!({ resume_path: file_path })

    render status: :ok
  rescue ActiveRecord::RecordNotFound => e
    Rails.logger.error e.message
    render status: :not_found
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error e.message
    File.delete(file_path) if File.exist? file_path
    render status: :bad_request
  rescue StandardError => e
    Rails.logger.error e.message
    render status: :service_unavailable
  end

  def show
    user_id = get_user_id_from_cookie(cookies[:trackitall_session_id])
    return render status: :unauthorized if user_id.nil?

    job_ulid = params[:job_ulid]
    job = Job.find(job_ulid)
    return render status: :not_found if job.nil?

    return render status: :not_found unless File.exist? job.resume_path

    File.open(job.resume_path, 'rb') do |f|
      send_data f.read, filename: File.basename(job.resume_path), type: 'application/pdf', disposition: 'attachment'
    end
  rescue StandardError => e
    Rails.logger.error e.message
    render status: :service_unavailable
  end

  def destroy
    user_id = get_user_id_from_cookie(cookies[:trackitall_session_id])
    return render status: :unauthorized if user_id.nil?

    job_ulid = params[:job_ulid]
    job = Job.find(job_ulid)
    return render status: :not_found if job.nil?

    return render status: :not_found unless File.exist? job.resume_path

    ActiveRecord::Base.transaction do
      # Store the path before setting it to nil.
      path_to_delete = job.resume_path
      job.update!({ resume_path: nil })

      File.delete(path_to_delete)
      raise ActiveRecord::Rollback, 'File deletion failed' if File.exist?(path_to_delete)

      render status: :no_content
    end
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error e.message
    render status: :bad_request
  rescue Errno::ENOENT
    # File already deleted, no further action needed.
    render status: :no_content
  rescue StandardError => e
    Rails.logger.error("Failed to delete file: #{e.message}")
    render status: :service_unavailable
  end
end
