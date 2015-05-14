module Immortus
  class Job < ActiveJob::Base
    # include InlineTrackingStrategy

    # cattr_accessor :inline_strategy
    after_enqueue :tracker_create
    before_perform :tracker_mark_started
    after_perform :tracker_finish_job

    def strategy
      @strategy ||= self.strategy_class.new
    end

    private

    def self.strategy_class
      Immortus::StrategyFinder.find
    end

    def tracker_create
      self.strategy.job_enqueued(self.job_id)
    end

    def tracker_mark_started
      self.strategy.job_started(self.job_id)
    end

    def tracker_finish_job
      self.strategy.job_finished(self.job_id)
    end
  end

  # module InlineTrackingStrategy
  #   include ActiveSupport::Concern

  #   class_methods do
  #     def tracking_stategy(strategy)
  #       self.inline_strategy = strategy
  #     end
  #   end
  # end
end
