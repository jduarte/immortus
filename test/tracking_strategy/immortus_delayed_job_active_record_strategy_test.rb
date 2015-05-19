require 'test_helper'
require 'spy/integration'
require 'delayed_job_active_record'

class ImmortusDelayedJobActiveRecordSstrategyTest < ActiveSupport::TestCase
  extend Minitest::Spec::DSL

  let(:delayed_job_strategy) { Immortus::TrackingStrategy::DelayedJobActiveRecordStrategy.new }
  let(:pending_job_id) { SecureRandom.uuid }
  let(:pending_job) { Delayed::Job.create(handler: "--- !ruby/object:ActiveJob::QueueAdapters::DelayedJobAdapter::JobWrapper\njob_data:\n  job_class: WaitABitJob\n  job_id: #{pending_job_id}\n  queue_name: default\n  arguments: []") }
  let(:processing_job_id) { SecureRandom.uuid }
  let(:processing_job) { Delayed::Job.create(handler: "--- !ruby/object:ActiveJob::QueueAdapters::DelayedJobAdapter::JobWrapper\njob_data:\n  job_class: WaitABitJob\n  job_id: #{processing_job_id}\n  queue_name: default\n  arguments: []", locked_at: Date.today, locked_by: 'someone') }
  let(:failed_job_id) { SecureRandom.uuid }
  let(:failed_job) { Delayed::Job.create(handler: "--- !ruby/object:ActiveJob::QueueAdapters::DelayedJobAdapter::JobWrapper\njob_data:\n  job_class: WaitABitJob\n  job_id: #{failed_job_id}\n  queue_name: default\n  arguments: []", attempts: 1, last_error: 'some error description') }
  let(:job_id) { SecureRandom.uuid }

  # we have no way to tell if that job ever existed or not since the job is deleted from the DB when it finished successfully
  # so we return :finished if the record does not exist in the DB
  test 'status :finished if invalid job that never ran' do
    assert_equal :finished, delayed_job_strategy.status(job_id)
  end

  test 'status :started' do
    processing_job
    assert_equal :started, delayed_job_strategy.status(processing_job_id)
  end

  test 'status :created' do
    pending_job
    assert_equal :created, delayed_job_strategy.status(pending_job_id)
  end
end
