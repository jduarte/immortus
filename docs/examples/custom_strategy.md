Image Processor
===

In this example:
* A user uploads a image to the server to be processed
* The UI will show job progress (percentage)

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

      result = { percentage: job.percentage }

      result[thumbnail] = job.thumbnail unless job.thumbnail.blank?

      result
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
var imageCreated = function(data) {
  $('.images').append('<div class="image-' + data.job_id + '"><span class="loading-icon"></span></div>');

  return { job_id: data.job_id, job_class: data.job_class };
};

var imageProcessed = function(data) {
  $('.images > .image-' + data.job_id).html('<img src="' + data.thumbnail + '">');
};

var imageNotProcessed = function(data) {
  alert('Image could not be processed');
};

var processingImage = function(data) {
  $('.images > .image-' + data.job_id).html('<span>progress: ' + data.percentage + '</span>');
};

Immortus.create('/process_image')
        .then(imageCreated)
        .then(function(jobInfo) {
          return Immortus.verify(jobInfo)
                         .then(imageProcessed, imageNotProcessed, processingImage);
        });
```

JavaScript Verify
---

We need this if we want the info to persist in a refresh

```html
<div class="image-908ec6f1-e093-4943-b7a8-7c84eccfe417"><span class="loading-icon"></span></div>
```

```javascript
// using some of the same functions from `JavaScript Create` section

var jobInfo = {
  job_id: '908ec6f1-e093-4943-b7a8-7c84eccfe417',
  job_class: 'ProcessImageJob'
};

Immortus.verify(jobInfo)
        .then(imageProcessed, imageNotProcessed, processingImage);
```

In this case we need to send `job_class` so __default verify__ could know what job is working with
