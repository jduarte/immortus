module Immortus
  class StrategyNotFound < StandardError; end

  class StrategyFinder
    MAP_ACTIVE_JOB_ADAPTER_TO_DEFAULT_STRATEGY = {
      delayed_job: :delayed_job_active_record,
      backburner: :not_implemented,
      qu: :not_implemented,
      que: :not_implemented,
      queue_classic: :not_implemented,
      resque: :not_implemented,
      sidekiq: :not_implemented,
      sneakers: :not_implemented,
      sucker_punch: :not_implemented,
      inline: :not_implemented,
      test: :empty
    }

    MAP_ACTIVE_JOB_ADAPTER_TO_REQUIREMENTS = {
      delayed_job: 'delayed_job_active_record',
      backburner: 'backburner',
      qu: 'qu',
      que: 'que',
      queue_classic: 'queue_classic',
      resque: ['resque', 'redis'],
      sidekiq: 'sidekiq',
      sneakers: 'sneakers',
      sucker_punch: 'sucker_punch',
      inline: nil,
      test: nil
    }

    def self.find
      strategy = immortus_config_strategy || active_job_adapter_default_strategy
      raise StrategyNotFound, 'Strategy does not seems to be setted' if strategy.blank?
      if strategy.is_a?(Class)
        strategy
      elsif strategy.is_a?(Symbol)
        begin
          "#{strategy.to_s.camelize}".constantize
        rescue
          default_namespace strategy
        end
      else
        raise StrategyNotFound, 'Strategy Not Found'
      end
    end

    private

    def self.immortus_config_strategy
      ::Rails.application.config.x.immortus.tracking_strategy
    end

    def self.active_job_adapter_default_strategy
      sym = ::Rails.application.config.active_job.queue_adapter

      strategy = default_namespace MAP_ACTIVE_JOB_ADAPTER_TO_DEFAULT_STRATEGY[sym]

      Array(MAP_ACTIVE_JOB_ADAPTER_TO_REQUIREMENTS[sym]).each do |requirement|
        require requirement
      end

      strategy
    end

    def self.default_namespace(strategy_class_sym)
      return nil if strategy_class_sym.blank?

      strategy_class_name = "#{strategy_class_sym}_strategy"

      begin
        "Immortus::TrackingStrategy::#{strategy_class_name.camelize}".constantize
      rescue
        raise StrategyNotFound, 'Could not find strategy in Immortus::TrackingStrategy namespace, please specify full namespace ex: MyApp::MyOverrides::MyCustomStrategy'
      end
    end
  end
end
