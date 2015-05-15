module Immortus
  class JobNotFound < StandardError; end

  class Job < ActiveJob::Base
    mattr_reader(:tracking_strategy)
    # include InlineTrackingStrategy

    def self.tracking_strategy=(strategy)
      @@tracking_strategy = strategy
    end

    # cattr_accessor :inline_strategy
    after_enqueue :tracker_create
    before_perform :tracker_mark_started
    after_perform :tracker_finish_job

    def strategy
      @strategy ||= strategy_class.new
    end

    private

    def strategy_class
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
