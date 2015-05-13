require 'test_helper'
require 'minitest/mock'
require 'minitest/spec'

class ImmortusJobTest < ActiveJob::TestCase
  extend Minitest::Spec::DSL

  let(:strategy_mock) { Minitest::Mock.new }

  def test_unknown_active_job_strategy
    ActiveJob::Base.queue_adapter = :test
    assert_raises RuntimeError do
      Immortus::Job.strategy
    end
  end

  def test_known_active_job_strategy
    ActiveJob::Base.queue_adapter = :delayed_job
    assert_equal Immortus::TrackingStrategy::DelayedJobStrategy, Immortus::Job.strategy.class
  end

  def test_override_strategy
    ::Rails.application.config.x.immortus.stub(:tracking_strategy, :delayed_job) do
      assert_equal Immortus::TrackingStrategy::DelayedJobStrategy, Immortus::Job.strategy.class
    end
  end

  def test_override_unknown_strategy
    ::Rails.application.config.x.immortus.stub(:tracking_strategy, :unknown) do
      assert_raises RuntimeError do
        Immortus::Job.strategy
      end
    end
  end

  def test_tracker_create_is_called
    strategy_mock.expect(:job_enqueued, nil, [String])

    WaitABitJob.stub(:strategy, strategy_mock) do
      WaitABitJob.perform_later
    end

    assert strategy_mock.verify
  end

  def test_tracker_mark_started_is_called
    strategy_mock.expect(:job_started, nil, [String])

    WaitABitJob.stub(:strategy, strategy_mock) do
      WaitABitJob.perform_now
    end

    assert strategy_mock.verify
  end

  def test_tracker_finish_job_is_called
    strategy_mock.expect(:job_finished, nil, [String])

    WaitABitJob.stub(:strategy, strategy_mock) do
      WaitABitJob.perform_now
    end

    assert strategy_mock.verify
  end
end
