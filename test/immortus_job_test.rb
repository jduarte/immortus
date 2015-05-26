require 'test_helper'
require 'minitest/mock'
require 'minitest/spec'
require 'spy/integration'
require 'immortus_empty_strategy'
require 'minitest/stub_any_instance'

class ImmortusJobTest < ActiveJob::TestCase
  extend Minitest::Spec::DSL

  def setup
    Immortus::Job.tracking_strategy = nil
  end

  let(:strategy_mock) { Minitest::Mock.new }
  let(:strategy_spy_mock) { Spy.mock(Immortus::TrackingStrategy::EmptyStrategy) }

  test 'job enqueued callback is called' do
    strategy_mock.expect(:job_enqueued, nil, [String])

    WaitABitJob.stub_any_instance(:strategy, strategy_mock) do
      WaitABitJob.perform_later
    end

    assert strategy_mock.verify
  end

  test 'job started callback is called' do
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

  test 'job finished callback is called' do
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

  test 'job finished callback should not be called if job execution raises an exception' do
    Spy.on(strategy_spy_mock, :job_started).and_call_through
    Spy.on(strategy_spy_mock, :job_enqueued).and_call_through
    job_finished_callback = Spy.on(strategy_spy_mock, :job_finished).and_call_through

    ErrorRaiseJob.stub_any_instance(:strategy, strategy_spy_mock) do
      perform_enqueued_jobs do
        begin
          ErrorRaiseJob.perform_later
        rescue
        end
      end
    end

    assert !job_finished_callback.has_been_called?
  end

  test 'strategy class should call StrategyFinder find' do
    find_spy = Spy.on(Immortus::StrategyFinder, :find)
    WaitABitJob.strategy_class
    assert find_spy.has_been_called?
  end

  test 'read tracking_strategy' do
    assert Immortus::Job.respond_to? :tracking_strategy
  end

  test 'write tracking_strategy' do
    some_strategy = :some_strategy
    Immortus::Job.tracking_strategy = some_strategy

    assert_equal some_strategy, Immortus::Job.tracking_strategy
  end
end
