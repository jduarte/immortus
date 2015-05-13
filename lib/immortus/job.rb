module Immortus
  class Job < ActiveJob::Base
    # include InlineTrackingStrategy

    # cattr_accessor :inline_strategy
    after_enqueue :tracker_create
    before_perform :tracker_mark_started
    after_perform :tracker_finish_job

    def self.strategy
      strat = immortus_config_strategy || active_job_adapter_default_strategy
      # strat = inline_strategy || immortus_config_strategy || active_job_adapter_default_strategy
      raise 'Strategy Not Found' if strat.blank?
      strategy_class = if strat.is_a?(Class)
        strat
      elsif strat.is_a?(Symbol)
        begin
          "#{strat.to_s.camelize}".constantize
        rescue
          default_namespace strat rescue raise 'Strategy Not Found'
        end
      end
      strategy_class.new
    end

    private

    def tracker_create
      self.class.strategy.job_enqueued(self.job_id)
    end

    def tracker_mark_started
      self.class.strategy.job_started(self.job_id)
    end

    def tracker_finish_job
      self.class.strategy.job_finished(self.job_id)
    end

    ACTIVE_JOB_ADAPTER_DEFAULT_STRATEGY = {
      DelayedJobAdapter: :delayed_job,
      BackburnerAdapter: :not_implemented,
      QuAdapter: :not_implemented,
      QueAdapter: :not_implemented,
      QueueClassicAdapter: :not_implemented,
      ResqueAdapter: :not_implemented,
      SidekiqAdapter: :not_implemented,
      SneakersAdapter: :not_implemented,
      SuckerPunchAdapter: :not_implemented,
      InlineAdapter: :not_implemented
    }

    def self.immortus_config_strategy
      ::Rails.application.config.x.immortus.tracking_strategy
    end

    def self.active_job_adapter_default_strategy
      sym = ActiveJob::Base.queue_adapter.name.split('::').last.to_sym
      return nil if sym == :not_implemented
      default_namespace ACTIVE_JOB_ADAPTER_DEFAULT_STRATEGY[sym]
    end

    def self.default_namespace(strategy_class_sym)
      strategy_class_name = "#{strategy_class_sym}_strategy"
      return nil if strategy_class_name.blank?
      "Immortus::TrackingStrategy::#{strategy_class_name.camelize}".constantize rescue raise 'Strategy Not Found'
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
