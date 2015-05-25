class ImmortusController < ActionController::Base
  def verify
    strategy = Immortus::Job.strategy_class.new

    meta = strategy.respond_to?(:meta) ? strategy.meta(params[:job_id]) : {}

    render json: {
      job_id: params[:job_id],
      completed: strategy.completed?(params[:job_id])
    }.merge(meta)
  end
end
