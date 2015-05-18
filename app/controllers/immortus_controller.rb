class ImmortusController < ActionController::Base
  def verify
    strategy_class = Immortus::StrategyFinder.find
    job_status = strategy_class.new.status(params[:job_id])

    success = nil
    success = true if [:finished_success].include?(job_status)
    success = false if [:finished_error].include?(job_status)

    render json: {
      success: success,
      completed: [:finished_error, :finished_success].include?(job_status)
    }
  end
end
