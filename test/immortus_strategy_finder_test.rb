require 'test_helper'
require 'minitest/mock'

class ImmortusStrategyFinderTest < ActiveJob::TestCase

  def setup
    Immortus::Job.tracking_strategy = nil
  end

  StrategyTestStruct = Struct.new(:active_job_queue_adapter,
                                  :immortus_job_tracking_strategy,
                                  :strategy_class)

  # #fail raise Immortus::StrategyNotFound
  test 'unknown active job strategy' do
    ::Rails.application.config.active_job.stub(:queue_adapter, :unknown) do
      assert_raises Immortus::StrategyNotFound do
        Immortus::StrategyFinder.find
      end
    end
  end

  test 'override unknown strategy' do
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
    test "inferred active job #{s.active_job_queue_adapter}" do
      ::Rails.application.config.active_job.stub(:queue_adapter, s.active_job_queue_adapter) do
        assert_equal Immortus::StrategyFinder.find, s.strategy_class
      end
    end

    test "override immortus job #{s.immortus_job_tracking_strategy}" do
      Immortus::Job.stub(:tracking_strategy, s.immortus_job_tracking_strategy) do
        assert_equal Immortus::StrategyFinder.find, s.strategy_class
      end
    end

    test "override immortus job #{s.strategy_class}" do
      Immortus::Job.stub(:tracking_strategy, s.strategy_class) do
        assert_equal Immortus::StrategyFinder.find, s.strategy_class
      end
    end
  end

  test 'custom strategy' do
    Immortus::Job.stub(:tracking_strategy, :custom_app_strategy) do
      assert_equal Immortus::StrategyFinder.find, TrackingStrategy::CustomAppStrategy
    end
  end

  test 'inline job strategy' do
    assert_equal TrackingStrategy::CustomAppStrategy, InlineStrategyJob.strategy_class
  end

end
