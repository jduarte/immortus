```ruby
# app/jobs/tracking_strategy/job_custom_verify_strategy.rb
module TrackingStrategy
  class JobCustomVerifyStrategy

    def job_enqueued(job_id)
      # Save in a custom table that this job was created
      JobCustomVerifyTable.create!(job_id: job_id, status: 'enqueued', percentage: 0)
    end

    def job_started(job_id)
      job = find(job_id)
      job.update_attributes(status: 'running')
    end

    def job_finished(job_id)
      job = find(job_id)
      job.update_attributes(status: 'finished', percentage: 100)
    end

    def update_percentage(job_id, percentage)
      job = find(job_id)
      job.update_attributes(percentage: percentage)
    end

    def percentage(job_id)
      job = find(job_id)
      job.percentage
    end

    def completed?(job_id)
      job = find(job_id)
      job.status == 'finished'
    end

    private

    def find(job_id)
      JobCustomVerifyTable.find_by(job_id: job_id)
    end

  end
end
```
