require 'test_helper'
require 'minitest/mock'

class ImmortusStrategyFinderTest < ActiveJob::TestCase
  def test_unknown_active_job_strategy
    ::Rails.application.config.active_job.stub(:queue_adapter, :unkwonw) do
      assert_raises Immortus::StrategyNotFound do
        Immortus::StrategyFinder.find
      end
    end
  end

  def test_known_active_job_strategy
    ::Rails.application.config.active_job.stub(:queue_adapter, :delayed_job) do
      assert_equal Immortus::TrackingStrategy::DelayedJobActiveRecordStrategy, Immortus::StrategyFinder.find
    end
  end

  def test_override_strategy_symbol
    ::Rails.application.config.x.immortus.stub(:tracking_strategy, :delayed_job_active_record) do
      assert_equal Immortus::TrackingStrategy::DelayedJobActiveRecordStrategy, Immortus::StrategyFinder.find
    end
  end

  def test_override_strategy_class
    ::Rails.application.config.x.immortus.stub(:tracking_strategy, Immortus::TrackingStrategy::DelayedJobActiveRecordStrategy) do
      assert_equal Immortus::TrackingStrategy::DelayedJobActiveRecordStrategy, Immortus::StrategyFinder.find
    end
  end

  def test_override_unknown_strategy
    ::Rails.application.config.x.immortus.stub(:tracking_strategy, :unknown) do
      assert_raises Immortus::StrategyNotFound do
        Immortus::StrategyFinder.find
      end
    end
  end
end
