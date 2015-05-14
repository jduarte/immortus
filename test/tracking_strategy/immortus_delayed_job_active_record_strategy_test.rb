require 'test_helper'
require 'spy/integration'
require 'delayed_job_active_record'

class ImmortusDelayedJobActiveRecordSstrategyTest < ActiveSupport::TestCase
  extend Minitest::Spec::DSL

  fake_pending_job_id = nil
  fake_pending_job = nil

  fake_processing_job_id = nil
  fake_processing_job = nil

  fake_failed_job_id = nil
  fake_failed_job = nil

  setup do
    fake_pending_job_id = 'fc6bb0d8-cca3-4777-8d0d-d531bc33c12f'
    fake_pending_job = Delayed::Job.create(handler: "--- !ruby/object:ActiveJob::QueueAdapters::DelayedJobAdapter::JobWrapper\njob_data:\n  job_class: WaitABitJob\n  job_id: #{fake_pending_job_id}\n  queue_name: default\n  arguments: []")
    fake_processing_job_id = '16bfda66-ec67-4027-9b53-d19a2041fdac'
    fake_processing_job = Delayed::Job.create(handler: "--- !ruby/object:ActiveJob::QueueAdapters::DelayedJobAdapter::JobWrapper\njob_data:\n  job_class: WaitABitJob\n  job_id: #{fake_processing_job_id}\n  queue_name: default\n  arguments: []", locked_at: Date.today, locked_by: 'someone')
    fake_failed_job_id = '9f10d492-34af-42bd-98c0-09a48e05609f'
    fake_failed_job = Delayed::Job.create(handler: "--- !ruby/object:ActiveJob::QueueAdapters::DelayedJobAdapter::JobWrapper\njob_data:\n  job_class: WaitABitJob\n  job_id: #{fake_failed_job_id}\n  queue_name: default\n  arguments: []", attempts: 1, last_error: 'some error description')
  end

  let(:delayed_job_strategy) { Immortus::TrackingStrategy::DelayedJobActiveRecordStrategy.new }
  let(:fake_job_id) { SecureRandom.uuid }

  test 'job enqueued does nothing' do
    # we don't expect nothing, all we need is done automatically by DelayedJob
    assert_equal nil, delayed_job_strategy.job_enqueued(fake_job_id)
  end

  test 'job started does nothing' do
    # we don't expect nothing, all we need is done automatically by DelayedJob
    assert_equal nil, delayed_job_strategy.job_started(fake_job_id)
  end

  test 'job finished does nothing' do
    # we don't expect nothing, all we need is done automatically by DelayedJob
    assert_equal nil, delayed_job_strategy.job_finished(fake_job_id)
  end

  test 'find known id' do
    assert_equal fake_pending_job, delayed_job_strategy.find(fake_pending_job_id)
  end

  test 'find unknown id' do
    assert_equal nil, delayed_job_strategy.find(fake_job_id)
  end

  test 'status :finished_success' do
    assert_equal :finished_success, delayed_job_strategy.status(fake_job_id)
  end

  test 'status :finished_error' do
    # WARNING: May be configured to delete failed jobs (DEFAULT behavior)
    assert_equal :finished_error, delayed_job_strategy.status(fake_failed_job_id)
  end

  test 'status :started' do
    assert_equal :started, delayed_job_strategy.status(fake_processing_job_id)
  end

  test 'status :created' do
    assert_equal :created, delayed_job_strategy.status(fake_pending_job_id)
  end
end
