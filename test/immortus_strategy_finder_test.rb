require 'test_helper'
require 'minitest/mock'

class ImmortusStrategyFinderTest < ActiveJob::TestCase

  StrategyTestStruct = Struct.new(:active_job_queue_adapter,
                                  :immortus_job_tracking_strategy,
                                  :strategy_class)

  # #fail raise Immortus::StrategyNotFound
  def test_unknown_active_job_strategy
    ::Rails.application.config.active_job.stub(:queue_adapter, :unkwown) do
      assert_raises Immortus::StrategyNotFound do
        Immortus::StrategyFinder.find
      end
    end
  end

  def test_override_unknown_strategy
    Immortus::Job.stub(:tracking_strategy, :unknown) do
      assert_raises Immortus::StrategyNotFound do
        Immortus::StrategyFinder.find
      end
    end
  end

  TestMatch = [
    StrategyTestStruct.new(:delayed_job, :delayed_job_active_record_strategy, Immortus::TrackingStrategy::DelayedJobActiveRecordStrategy)
    # StrategyTestStruct.new(:sideqik, :redis_strategy, Immortus::TrackingStrategy::RedisStrategy)
  ]

  TestMatch.each do |s|
    define_method("test_inferred_active_job_#{s.active_job_queue_adapter}") do
      ::Rails.application.config.active_job.stub(:queue_adapter, s.active_job_queue_adapter) do
        assert_equal Immortus::StrategyFinder.find, s.strategy_class
      end
    end

    define_method("test_override_immortus_job_#{s.immortus_job_tracking_strategy}") do
      Immortus::Job.stub(:tracking_strategy, s.immortus_job_tracking_strategy) do
        assert_equal Immortus::StrategyFinder.find, s.strategy_class
      end
    end

    define_method("test_override_immortus_job_#{s.strategy_class}") do
      Immortus::Job.stub(:tracking_strategy, s.strategy_class) do
        assert_equal Immortus::StrategyFinder.find, s.strategy_class
      end
    end
  end

  def test_custom_strategy
    Immortus::Job.stub(:tracking_strategy, :custom_app_strategy) do
      assert_equal Immortus::StrategyFinder.find, TrackingStrategy::CustomAppStrategy
    end
  end

end
