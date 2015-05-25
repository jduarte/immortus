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
  # let(:failed_job_id) { SecureRandom.uuid }
  # let(:failed_job) { Delayed::Job.create(handler: "--- !ruby/object:ActiveJob::QueueAdapters::DelayedJobAdapter::JobWrapper\njob_data:\n  job_class: WaitABitJob\n  job_id: #{failed_job_id}\n  queue_name: default\n  arguments: []", attempts: 1, last_error: 'some error description') }
  let(:job_id) { SecureRandom.uuid }

  test 'unknown job is finished' do
    # we have no way to tell if that job ever existed or not
    # since the job is deleted from the DB when it finished successfully
    # so we return :finished if the record does not exist in the DB
    assert_equal true, delayed_job_strategy.completed?(job_id)
  end

  test 'processed job is not finished' do
    processing_job
    assert_equal false, delayed_job_strategy.completed?(processing_job_id)
  end

  test 'pending job is not finished' do
    pending_job
    assert_equal false, delayed_job_strategy.completed?(pending_job_id)
  end

  test 'strategy has completed method' do
    assert_equal true, delayed_job_strategy.respond_to?('completed?')
  end
end
