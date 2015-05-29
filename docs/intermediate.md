Intermediate Immortus Details
===

In this example we assume:

- you will create a new background job
- you need an extra field to be displayed (percentage)
- you may have more then one strategy configured globally

Routes (file: config/routes.rb)
---

```ruby
Rails.application.routes.draw do
  # ...

  immortus_jobs do
    post 'generate_job', to: 'job#generate'
  end

  # same as write:
  # get '/immortus/verify/:job_id(/:job_class)', to: 'immortus#verify'
  # post 'generate_job', to: 'job#generate'
end
```

Tracking Strategy
---

```ruby
# app/jobs/tracking_strategy/my_custom_tracking_strategy.rb
module TrackingStrategy
  class MyCustomTrackingStrategy

    def job_enqueued(job_id)
      MyCustomTrackingJobTable.create!(job_id: job_id, status: 'created', percentage: 0)
    end

    def job_started(job_id)
      find(job_id).update_attributes(status: 'started')
    end

    def job_finished(job_id)
      job = find(job_id)
      job.update_attributes(status: 'finished', percentage: 100)
    end

    def update_percentage(job_id, percentage)
      job = find(job_id)
      job.update_attributes(percentage: percentage)
    end

    # completed? method is mandatory, should return a boolean ( true if job is finished, false otherwise )
    def completed?(job_id)
      job = find(job_id)
      job.status == 'finished'
    end

    # if meta method is defined, the returned hash will be added in every verify request
    def meta(job_id)
      job = find(job_id)

      {
        percentage: job.percentage
      }
    end

    private

    def find(job_id)
      MyCustomTrackingJobTable.find_by(job_id: job_id)
    end
  end
end
```

In this case we need to create a `meta(job_id)` method so __default verify__ can send extra data (percentage) to JS.

Job
---

Just add `include Immortus::Job` into your ActiveJob. Example:

```ruby
# app/jobs/my_job.rb
class MyJob < ActiveJob::Base
  include Immortus::Job

  tracking_strategy :my_custom_tracking_strategy

  def perform(record)
    # Do stuff ...
    # self.strategy.update_percentage(job_id, percentage)
  end
end
```

Generate job method
---

```ruby
class JobController < ApplicationController
  def generate
    job = MyJob.perform_later
    render_immortus job

    # `render_immortus job` is same as write:
    # if job.try('job_id')
    #   render json: { job_id: job.job_id, job_class: job.class.name }
    # else
    #   render json: {}, status: 500
    # end
  end
end
```

JS Create
---

```javascript
var jobFinished = function(data) {
  // Job was completed here. `data` has the info returned in the 'Intermediate', 'Explicit' `JobController#verify`
  console.log(data.job_id + ' finished successfully.');
};

var jobFailed = function(data) {
  console.log('error in job ' + data.job_id);
};

var jobInProgress = function(data) {
  // logic to update percentage with `data.percentage` ... which came from meta method
};

Immortus.create('/generate_invoice')
        .then(function(data) {
          return Immortus.verify({ jobId: data.job_id })
                         .then(jobFinished, jobFailed, jobInProgress);
        });
```

In this example we assume that creation of job never fail (if it fails it does nothing)

JS Verify
---

```javascript
var jobFinished = function(data) {
  // Job was completed here. `data` has the info returned in the `JobCustomVerifyController#verify`
  console.log(data.job_id + ' finished successfully.');
};

var jobFailed = function(data) {
  console.log('error in job ' + data.job_id);
};

var jobInProgress = function(data) {
  // logic to update percentage with `data.percentage` ... which came from meta method
};

var jobInfo = {
  jobId: '908ec6f1-e093-4943-b7a8-7c84eccfe417',
  jobClass: 'my_job'
};

var options = {
  longPolling: {
    interval: 800
  }
};

Immortus.verify(jobInfo, options)
        .then(jobFinished, jobFailed, jobInProgress);
```

In this case we need to send `jobClass` so __default verify__ could know what job is working with
