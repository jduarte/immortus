class ImmortusController < ActionController::Base
  def verify
    meta = strategy.respond_to?(:meta) ? strategy.meta(params[:job_id]) : {}

    render json: {
      job_id: params[:job_id],
      completed: strategy.completed?(params[:job_id])
    }.merge(meta)
  rescue
    render json: { job_id: params[:job_id] }, status: 500
  end

  private

  def strategy
    @strategy ||= strategy_class.new
  end

  def strategy_class
    if params[:job_class] && (!!Module.const_get(params[:job_class]) rescue false)
      params[:job_class].constantize.strategy_class
    else
      Immortus::StrategyFinder.find
    end
  end
end
