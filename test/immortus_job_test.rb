require 'test_helper'
require 'minitest/mock'
require 'minitest/spec'
require 'spy/integration'
require 'immortus_empty_strategy'
require 'minitest/stub_any_instance'

class ImmortusJobTest < ActiveJob::TestCase
  extend Minitest::Spec::DSL

  let(:strategy_mock) { Minitest::Mock.new }
  let(:strategy_spy_mock) { Spy.mock(Immortus::TrackingStrategy::EmptyStrategy) }

  def test_check_if_job_enqueue_callback_is_called
    strategy_mock.expect(:job_enqueued, nil, [String])

    WaitABitJob.stub_any_instance(:strategy, strategy_mock) do
      WaitABitJob.perform_later
    end

    assert strategy_mock.verify
  end

  def test_check_if_job_started_callback_is_called
    Spy.on(strategy_spy_mock, :job_enqueued).and_call_through
    job_started_callback = Spy.on(strategy_spy_mock, :job_started).and_call_through
    Spy.on(strategy_spy_mock, :job_finished).and_call_through

    WaitABitJob.stub_any_instance(:strategy, strategy_spy_mock) do
      perform_enqueued_jobs do
        WaitABitJob.perform_later
      end
    end

    assert job_started_callback.has_been_called?
  end

  def test_check_if_fob_finished_callback_is_called
    Spy.on(strategy_spy_mock, :job_enqueued).and_call_through
    Spy.on(strategy_spy_mock, :job_started).and_call_through
    job_finished_callback = Spy.on(strategy_spy_mock, :job_finished).and_call_through

    WaitABitJob.stub_any_instance(:strategy, strategy_spy_mock) do
      perform_enqueued_jobs do
        WaitABitJob.perform_later
      end
    end

    assert job_finished_callback.has_been_called?
  end
end
