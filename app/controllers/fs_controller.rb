class FsController < ApplicationController
  def new
    user_id = get_user_id_from_cookie(cookies[:trackitall_session_id])
    return render status: :unauthorized if user_id.nil?

    job_ulid = params[:job_ulid]
    job = Job.find(job_ulid)
    return render status: :not_found if job.nil?

    file = params[:file]
    return render status: :bad_request unless file.present?

    resume_dir = File.join(ENV['FILE_STORAGE_PATH'], 'resume', user_id)
    Dir.mkdir resume_dir unless Dir.exist? resume_dir

    resume_path = File.join(resume_dir, "#{job_ulid}_#{file.original_filename}")
    File.open(resume_path, 'wb') do |f|
      f.write(file.read)
    end

    resume_content = parse_resume(resume_path)

    ActiveRecord::Base.transaction do
      content_updated = job.update({ resume_content: })
      raise ActiveRecord::Rollback, 'Failed to update db resume_content' unless content_updated

      path_updated = job.update({ resume_path: })
      raise ActiveRecord::Rollback, 'Failed to update db resume_path' unless path_updated

      render status: :ok
    end
  rescue ActiveRecord::RecordNotFound => e
    Rails.logger.error e.message
    render status: :not_found
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error e.message
    File.delete(resume_path) if File.exist? resume_path
    render status: :bad_request
  rescue StandardError, ActiveRecord::Rollback => e
    Rails.logger.error e.message
    render status: :service_unavailable
    File.delete(resume_path) if File.exist? resume_path
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

  protected

  def parse_resume(resume_path)
    reader = PDF::Reader.new(resume_path)
    resume_content = ''
    reader.pages.each do |page|
      resume_content += page.text
    end

    resume_content
  end
end
