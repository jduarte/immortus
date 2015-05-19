class ImmortusController < ActionController::Base
  def verify
    job_status = Immortus::Job.strategy_class.new.status(params[:job_id])

    success = nil
    success = true if job_status == :finished

    render json: {
      success: success,
      completed: job_status == :finished
    }
  end
end
