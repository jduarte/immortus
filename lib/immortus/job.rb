module Immortus
  class Job < ActiveJob::Base
    cattr_reader(:tracking_strategy)

    def self.tracking_strategy=(strategy)
      @@tracking_strategy = strategy
    end

    after_enqueue :tracker_create
    before_perform :tracker_mark_started
    after_perform :tracker_finish_job

    def strategy
      @strategy ||= strategy_class.new
    end

    def self.strategy_class
      Immortus::StrategyFinder.find
    end

    private

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
end
