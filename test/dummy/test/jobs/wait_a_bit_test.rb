require 'test_helper'

class WaitABitJobTest < ActiveJob::TestCase
  test 'job has run' do
    job = WaitABitJob.perform_later
    assert job.job_id
  end
end
