module Immortus
  class StrategyNotFound < StandardError; end

  class StrategyFinder
    ACTIVE_JOB_INFERRED_STRATEGIES = {
      delayed_job:    :delayed_job_active_record_strategy,
      backburner:     :not_implemented,
      qu:             :not_implemented,
      que:            :not_implemented,
      queue_classic:  :not_implemented,
      resque:         :not_implemented,
      sidekiq:        :sidekiq_strategy,
      sneakers:       :not_implemented,
      sucker_punch:   :not_implemented,
      inline:         :not_implemented,
      test:           :empty
    }

    ADAPTER_REQUIREMENTS = {
      delayed_job:    'delayed_job_active_record',
      backburner:     'backburner',
      qu:             'qu',
      que:            'que',
      queue_classic:  'queue_classic',
      resque:         ['resque', 'redis'],
      sidekiq:        'sidekiq',
      sneakers:       'sneakers',
      sucker_punch:   'sucker_punch',
      inline:         nil,
      test:           nil
    }

    def self.find
      strategy = immortus_config_strategy || active_job_adapter_default_strategy
      raise StrategyNotFound, 'Strategy is not set in the configuration' if strategy.blank?

      return strategy if strategy.is_a?(Class)
      load_strategy_class(strategy)
    end

    private

    def self.immortus_config_strategy
      Immortus::Job.tracking_strategy
    end

    def self.active_job_adapter_default_strategy
      aj_queue_adapter = ::Rails.application.config.active_job.queue_adapter

      strategy = load_strategy_class(ACTIVE_JOB_INFERRED_STRATEGIES[aj_queue_adapter])

      Array(ADAPTER_REQUIREMENTS[aj_queue_adapter]).compact.each do |requirement|
        require requirement
      end

      strategy
    end

    def self.load_strategy_class(name)
      class_name = "Immortus::TrackingStrategy::#{name.to_s.camelize}"
      non_namespace = "TrackingStrategy::#{name.to_s.camelize}"

      [class_name, non_namespace].each do |k_name|
        class_exists = !!Module.const_get(k_name) rescue false
        return k_name.constantize if class_exists
      end

      raise StrategyNotFound, "Could not find Strategy. Tried `#{class_name}` and `#{non_namespace}`"
    end
  end
end
