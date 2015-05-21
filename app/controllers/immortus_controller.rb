class ImmortusController < ActionController::Base
  def verify
    strategy = Immortus::Job.strategy_class.new
    job_status = strategy.status(params[:job_id])

    meta = strategy.respond_to?(:meta) ? strategy.meta : {}

    render json: {
      meta: meta,
      status: job_status,
      completed: job_status == :finished
    }
  end
end
