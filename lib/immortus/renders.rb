module ActionController
  module Rendering

    def render_immortus(job)
      if job.try('job_id')
        render_immortus_success job.job_id
      else
        render_immortus_error "An error occurred enqueing the job. #{job.error_exception}"
      end
    end

    private

    def render_immortus_success(job_id)
      render json: { job_id: job_id }
    end

    def render_immortus_error(error)
      render json: { error: error }, status: 500
    end
  end
end
