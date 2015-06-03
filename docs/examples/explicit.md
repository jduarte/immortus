Create a Job to send emails and track his progress
===

In this example we need to access __current_user__ to get __total_sent_emails_this_week__ to JavaScript.
We don't have access to __current_user__ inside Tracking Strategy, so we need to create a __custom verify__.

Routes (file: config/routes.rb)
---

```ruby
Rails.application.routes.draw do
  # ...

  immortus_jobs do
    get 'job_custom_verify/:job_id', to: 'job_custom_verify#verify'
    post '/email_everyone', :to => 'job#email_everyone'
  end
end
```

Tracking Strategy
---

```ruby
# app/jobs/tracking_strategy/job_custom_verify_strategy.rb
module TrackingStrategy
  class JobCustomVerifyStrategy

    def job_started(job_id)
      email_batch = find(job_id)
      email_batch.update_attributes(status: 'running')
    end

    def job_finished(job_id)
      email_batch = find(job_id)
      email_batch.update_attributes(status: 'finished', percentage: 100)
    end

    def update_progress(job_id, percentage)
      email_batch = find(job_id)
      email_batch.update_attributes(percentage: percentage)
    end

    def progress(job_id)
      email_batch = find(job_id)
      email_batch.percentage
    end

    def status(job_id)
      email_batch = find(job_id)
      email_batch.status
    end

    def completed?(job_id)
      email_batch = find(job_id)
      email_batch.status == 'finished'
    end

    private

    def find(job_id)
      EmailBatchTable.find_by(job_id: job_id)
    end

  end
end
```

Job
---

Just add `include Immortus::Job` into your ActiveJob. Example:

```ruby
# app/jobs/send_email_batch_job.rb
class SendEmailBatchJob < ActiveJob::Base
  include Immortus::Job

  tracking_strategy :job_custom_verify_strategy

  def perform(email_body, email_subject)
    # Send email_body to everyone with email_subject
    # to update progress we should use:
    #   self.strategy.update_progress(job_id, percentage)
    #   or
    #   EmailBatchTable.find_by(job_id: job_id).update_attributes(percentage: percentage)
  end
end
```

Custom verify
---

```ruby
# app/controllers/job_custom_verify_controller.rb
class JobCustomVerifyController < ApplicationController
  def verify
    strategy = SendEmailBatchJob.strategy

    render json: {
      :completed => strategy.completed?(params[:job_id]),
      :percentage => strategy.progress(params[:job_id]),
      :status => strategy.status(params[:job_id]),
      :total_email_batch_sent_this_week => current_user.total_email_batch_sent_this_week
    }
  end
end
```

returned `json` will be available in `data` within JavaScript callbacks

`completed` must be one of returned `json` parameters, so JavaScript knows when to stop polling

Send Email Batch method
---

```ruby
class JobController < ApplicationController
  def email_everyone
    row = EmailBatchTable.new(status: 'enqueued', percentage: 0)

    job = SendEmailBatchJob.perform_later(params['body'], params['subject'])

    job_id = job.try('job_id')

    row.job_id = job_id

    if !job_id.blank? && row.save!
      render json: { job_id: job_id, job_class: job.class.name }
    else
      render json: {}, status: 500
    end
  end
end
```

JavaScript Create
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
  // logic to finish, like show notification with success message
  // add some warning if `total_email_batch_sent_this_week` is high, to avoid spam
};

var jobFailed = function(data) {
  alert('Job ' + data.job_id + ' failed to perform');
};

var jobInProgress = function(data) {
  // logic to update percentage if `data.status` === 'running' with `data.percentage`, which came from meta method
};

Immortus.create('/process_image')
        .then(jobCreatedSuccessfully, jobFailedToCreate)
        .then(function(jobInfo) {
          var verifyJobUrl = '/job_custom_verify/' + jobInfo.job_id;
          return Immortus.verify({ verify_job_url: verifyJobUrl }, { polling: { interval: 1800 } })
                         .then(jobFinished, jobFailed, jobInProgress);
        });
```

JavaScript Verify
---

```javascript
// using some of the same functions from `JavaScript Create` section

var jobInfo = {
  verify_job_url: '/job_custom_verify/908ec6f1-e093-4943-b7a8-7c84eccfe417'
};

Immortus.verify(jobInfo, { polling: { interval: 1800 } })
        .then(jobFinished, jobFailed, jobInProgress);
```
