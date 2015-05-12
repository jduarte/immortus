class ImmortusController < ApplicationController
  def verify
    job_status = Immortus::Job.strategy.status params[:job_id]

    render json: {
      success: ![:finished_error].include?(job_status),
      completed: [:finished_error, :finished_success].include?(job_status),
      status_text: job_status
    }
  end
end
