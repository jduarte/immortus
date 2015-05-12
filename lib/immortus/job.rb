module Immortus
  class Job < ActiveJob::Base
    # include InlineTrackingStrategy

    # cattr_accessor :inline_strategy
    after_enqueue :tracker_create
    before_perform :tracker_mark_started
    after_perform :tracker_finish_job

    def self.strategy
      strat = immortus_config_strategy || active_job_adapter_default_strategy # inline_strategy || immortus_config_strategy || active_job_adapter_default_strategy
      strategy_class = if strat.is_a?(Class)
        strat
      elsif strat.is_a?(Symbol)
        "#{strat.to_s.camelize}".constantize
      end
      strategy_class.new
    end

    private

    def tracker_create
      Immortus::Job.strategy.job_enqueued(self.job_id)
    end

    def tracker_mark_started
      Immortus::Job.strategy.job_started(self.job_id)
    end

    def tracker_finish_job
      Immortus::Job.strategy.job_finished(self.job_id)
    end

    def self.immortus_config_strategy
      ::Rails.application.config.try('immortus').try('tracking_strategy')
    end

    ACTIVE_JOB_ADAPTER_DEFAULT_STRATEGY = {
      delayed_job: :delayed_job_strategy,
      backburner: :not_implemented_strategy,
      qu: :not_implemented_strategy,
      que: :not_implemented_strategy,
      queue_classic: :not_implemented_strategy,
      resque: :not_implemented_strategy,
      sidekiq: :not_implemented_strategy,
      sneakers: :not_implemented_strategy,
      sucker_punch: :not_implemented_strategy,
      inline: :not_implemented_strategy
    }

    def self.active_job_adapter_default_strategy
      sym = ::Rails.application.config.active_job.queue_adapter
      strategy_class_name = "#{ACTIVE_JOB_ADAPTER_DEFAULT_STRATEGY[sym]}"
      "Immortus::TrackingStrategy::#{strategy_class_name.camelize}".constantize
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

