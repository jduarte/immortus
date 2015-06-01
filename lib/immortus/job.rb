module Immortus
  module Job
    # global config (initializer)
    cattr_accessor :tracking_strategy

    def self.included(base)
      base.extend ClassMethods
      base.class_eval do
        after_enqueue :tracker_create
        before_perform :tracker_mark_started
        after_perform :tracker_finish_job

        def strategy
          @strategy ||= self.class.strategy_class.new
        end

        private

        def tracker_create
          self.strategy.job_enqueued(self.job_id) if self.strategy.respond_to?(:job_enqueued)
        end

        def tracker_mark_started
          self.strategy.job_started(self.job_id) if self.strategy.respond_to?(:job_started)
        end

        def tracker_finish_job
          self.strategy.job_finished(self.job_id) if self.strategy.respond_to?(:job_finished)
        end
      end
    end

    module ClassMethods
      attr_reader :inline_tracking_strategy

      def strategy_class
        if inline_tracking_strategy
          Immortus::StrategyFinder.load_strategy_class(inline_tracking_strategy)
        else
          Immortus::StrategyFinder.find
        end
      end

      # inline config (job)
      def tracking_strategy(strategy)
        @inline_tracking_strategy = strategy
      end
    end
  end
end
