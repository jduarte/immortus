module ActionController
  module Rendering
    def render_immortus(job)
      if job.try('job_id')
        render json: { job_id: job.job_id, job_class: job.class.name }
      else
        render json: { job_id: job.job_id }, status: 500
      end
    end
  end
end
