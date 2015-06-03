Create a Job to process an image and update the progress in UI
===

Routes (file: config/routes.rb)
---

```ruby
Rails.application.routes.draw do
  # ...

  immortus_jobs do
    post 'process_image', to: 'image#process'
  end
end
```

Tracking Strategy
---

```ruby
# app/jobs/tracking_strategy/process_image_strategy.rb
module TrackingStrategy
  class ProcessImageStrategy

    def job_enqueued(job_id)
      ProcessImageTable.create!(job_id: job_id, status: 'enqueued', percentage: 0)
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

    def completed?(job_id)
      job = find(job_id)
      job.status == 'finished'
    end

    def meta(job_id)
      job = find(job_id)

      {
        percentage: job.percentage
      }
    end

    private

    def find(job_id)
      ProcessImageTable.find_by(job_id: job_id)
    end
  end
end
```

In this case we need to create a `meta(job_id)` method so __default verify__ can send extra data (percentage) to JS.

Job
---

```ruby
# app/jobs/process_image_job.rb
class ProcessImageJob < ActiveJob::Base
  include Immortus::Job

  tracking_strategy :process_image_strategy

  def perform(record)
    # do some heavy processing ...
    # update job percentage by using:
    #   self.strategy.update_percentage(job_id, percentage)
  end
end
```

Generate job method
---

```ruby
class ImageController < ApplicationController
  def process
    job = ProcessImageJob.perform_later
    render_immortus job
  end
end
```

JavaScript Create
---

```javascript
var jobCreatedSuccessfully = function(data) {
  // logic to add some loading gif

  return { job_id: data.job_id, job_class: data.job_class };
};

var jobFailedToCreate = function() {
  alert('Job failed to create');
};

var jobFinished = function(data) {
  // logic to finish ... like show image thumbnail
};

var jobFailed = function(data) {
  alert('Job failed');
};

var jobInProgress = function(data) {
  // logic to update percentage with `data.percentage` ... which came from meta method
};

Immortus.create('/process_image')
        .then(jobCreatedSuccessfully, jobFailedToCreate)
        .then(function(jobInfo) {
          return Immortus.verify(jobInfo)
                         .then(jobFinished, jobFailed, jobInProgress);
        });
```

JavaScript Verify
---

we need this if we want the info to persist in a refresh

```javascript
// using some of the same functions from `JavaScript Create` section

var jobInfo = {
  job_id: '908ec6f1-e093-4943-b7a8-7c84eccfe417',
  job_class: 'ProcessImageJob'
};

Immortus.verify(jobInfo)
        .then(jobFinished, jobFailed, jobInProgress);
```

In this case we need to send `job_class` so __default verify__ could know what job is working with
