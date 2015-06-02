Create a Job and track progress with custom verify
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

  get  'job_custom_verify/:job_id', to: 'job_custom_verify#verify'
  post '/generate_job', :to => 'job#generate'
end
```

This should be used if we explicitly want to see what is going on or if we don't need __default verify__ (case presented).

In this case we also need the custom verify, defined in __Verify job method__ section

Tracking Strategy
---

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

Job
---

Just add `include Immortus::Job` into your ActiveJob. Example:

```ruby
# app/jobs/my_job.rb
class MyJob < ActiveJob::Base
  include Immortus::Job

  tracking_strategy :job_custom_verify_strategy

  def perform(record)
    # Do stuff ...
    # self.strategy.update_percentage(job_id, percentage)
  end
end
```

Verify job method
---

```ruby
# app/controllers/job_custom_verify_controller.rb
class JobCustomVerifyController < ApplicationController
  def verify
    strategy = MyJob.strategy

    render json: {
      :completed => strategy.completed?(params[:job_id]),
      :percentage => strategy.percentage(params[:job_id])
    }
  end
end
```

returned `json` will be available in `data` within JS callbacks

`completed` must be one of returned `json` parameters, so JS knows when to stop long polling

Generate job method
---

```ruby
class JobController < ApplicationController
  def generate
    job = MyJob.perform_later
    if job.try('job_id')
      render json: { job_id: job.job_id, job_class: job.class.name }
    else
      render json: {}, status: 500
    end
  end
end
```

This example do __exactly__ the same as previous one.
This should be used if we explicitly want to see what is going on or you need to add more info to __JS Create__ Callbacks

JS Create
---

```javascript
var jobCreatedSuccessfully = function(data) {
  // logic to add some loading gif

  return { job_id: data.job_id };
};

var jobFailedToCreate = function() {
  alert('Job failed to create');
};

var jobFinished = function(data) {
  // logic to finish ... like show image thumbnail
};

var jobFailed = function(data) {
  alert('Job ' + data.job_id + ' failed to perform');
};

var jobInProgress = function(data) {
  // logic to update percentage with `data.percentage` ... which came from meta method
};

Immortus.create('/process_image')
        .then(jobCreatedSuccessfully, jobFailedToCreate)
        .then(function(jobInfo) {
          var verifyJobUrl = '/job_custom_verify/' + jobInfo.job_id;
          return Immortus.verify({ verify_job_url: verifyJobUrl }, { long_polling: { interval: 1800 } })
                         .then(jobFinished, jobFailed, jobInProgress);
        });
```

In this example, we differ from Intermediate by handling creation success/error, and setting long polling parameters just to show what we can control.

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
  verify_job_url: '/job_custom_verify/908ec6f1-e093-4943-b7a8-7c84eccfe417'
};

var options = {
  long_polling: {
    interval: 800
  }
};

Immortus.verify(jobInfo, options)
        .then(jobFinished, jobFailed, jobInProgress);
```
