require 'test_helper'
require 'spy/integration'
require 'delayed_job_active_record'

class ImmortusDelayedJobActiveRecordSstrategyTest < ActiveSupport::TestCase
  extend Minitest::Spec::DSL

  let(:delayed_job_strategy) { Immortus::TrackingStrategy::DelayedJobActiveRecordStrategy.new }

  test 'job enqueued' do
    # we don't expect nothing, all we need is done automatically by DelayedJob
    assert_equal nil, delayed_job_strategy.job_enqueued(1)
  end

  test 'job started' do
    # we don't expect nothing, all we need is done automatically by DelayedJob
    assert_equal nil, delayed_job_strategy.job_started(1)
  end

  test 'job finished' do
    # we don't expect nothing, all we need is done automatically by DelayedJob
    assert_equal nil, delayed_job_strategy.job_finished(1)
  end

  test 'find' do
    assert_equal nil, delayed_job_strategy.find(1)
  end

  test 'status :finished_success' do
    assert_equal :finished_success, delayed_job_strategy.status(1)
  end

  test 'status :finished_error' do
    assert_equal :finished_error, delayed_job_strategy.status(2)
  end

  test 'status :started' do
    assert_equal :started, delayed_job_strategy.status(3)
  end

  test 'status :created' do
    assert_equal :created, delayed_job_strategy.status(4)
  end
end
