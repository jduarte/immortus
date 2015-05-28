Immortus Details
===

Since it's mandatory to be used at least one verify method, so we can check if the job is finished, we created one, doe to convenience, and from now on we will call it __default verify__

In this section we are specifying 3 ways of dealing with things:

- Minimalistic ( more syntactic sugar / hidden behavior ) - we assume you already have jobs created and just need to know when they finish and just want to change the minimum possible
- Intermediate - we assume you will create a new background job with an extra field (percentage)
- Explicit ( clear as water ) - have full control on what is going on doing the same as Intermediate way

In your use case you can mix some of these,
this is just a detailed example to try to avoid doubts on how should you do things with `Immortus`.

Routes (file: config/routes.rb)
---

##### Minimalistic

```ruby
Rails.application.routes.draw do
  # ...

  immortus_jobs

  # same as write:
  # get '/immortus/verify/:job_id(/:job_class)', to: 'immortus#verify'
end
```

This is the simplest case possible (regarding routing),
to be used when you already got routes to create background jobs
and just need to add the __default verify__ so the JS be able to check the job status.

##### Intermediate

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

The block given will yield exactly as is with the __default verify__ route on top,
we do this to remove the need of adding the __default verify__ route
and to be possible to have a place for all jobs creation calls (like name-spacing)

##### Explicit

```ruby
Rails.application.routes.draw do
  # ...

  get  'job_custom_verify/:job_id', to: 'job_custom_verify#verify'
  post '/generate_job', :to => 'job#generate'
end
```

This should be used if we explicitly want to see what is going on or if we don't need __default verify__ (case presented).

In this case we also need the custom verify, defined in __Verify job method__ section

Job
---

Just add `include Immortus::Job` into your ActiveJob. Example:

```ruby
# app/jobs/generate_invoice_job.rb
class MyJob < ActiveJob::Base
  include Immortus::Job

  def perform(record)
    # Do stuff ...
  end
end
```

Tracking Strategy
---

This is how we keep track of any job

##### Minimalistic

If you just need to check job completeness you could use the default strategy

##### Intermediate

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

We also need a way to update percentage, it should be called inside our job perform method something like:

```ruby
self.strategy.update_percentage(job_id, percentage)
```

our job should also have so it can use this strategy
```ruby
tracking_strategy :my_custom_tracking_strategy
```

##### Explicit

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

To update percentage, it should be called inside our job perform method something like:

```ruby
self.strategy.update_percentage(job_id, percentage)
```

our job should also have so it can use this strategy
```ruby
tracking_strategy :job_custom_verify_strategy
```

How to add a Custom Traking Strategy to a Job
---

To find which strategy should be used to track a specific job first it will see if specified job has a in-line definition

```ruby
# app/jobs/some_job.rb
class SomeJob < Immortus::Job
  tracking_strategy :my_custom_tracking_strategy

  def perform(record)
    # Do stuff ...
  end
end
```

if not it will try to find in a global configuration

```ruby
# config/initializer/immortus.rb
immortus::Job.tracking_strategy = :my_custom_tracking_strategy
```

if not it will infer from ActiveJob (default behavior)

Verify job method
---

##### Minimalistic & Intermediate

We use __default verify__ in both these cases, so nothing to do here.

##### Explicit

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

##### Minimalistic

If you already create the job in your current APP you don't need to worry with this step

##### Intermediate

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

If you are adding a new job created by a JS call (we explain this in detail in __JS Create__ section)

##### Explicit

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

JS
---

Require Immortus in your manifest file ( make sure jQuery is included at this point ):

```javascript
//= ...
//= require immortus
```

JS Create
---

We use jQuery Promises for more details check [jQuery deferred API](http://api.jquery.com/category/deferred-object/)

##### Minimalistic

In simplest case you already create background jobs. so nothing to do here.

##### Intermediate

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
        .done(function(data) {
          return Immortus.verify({ jobId: data.job_id })
                         .then(jobFinished, jobFailed, jobInProgress);
        });
```

In this example we assume that creation of job never fail (if it fails it does nothing)

##### Explicit

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
  alert('Job ' + data.job_id + ' failed to perform');
};

var jobInProgress = function(data) {
  // logic to update percentage with `data.percentage` ... which came from meta method
};

Immortus.create('/process_image')
        .then(jobCreatedSuccessfully, jobFailedToCreate)
        .then(function(jobInfo) {
          jobInfo.verifyJobUrl = '/job_custom_verify/908ec6f1-e093-4943-b7a8-7c84eccfe417';
          return Immortus.verify(jobInfo, { longPolling: { interval: 1800 } })
                         .then(jobFinished, jobFailed, jobInProgress);
        });
```

In this example, we differ from Intermediate by handling creation success/error, and setting long polling parameters just to show what we can control.

For all the options check the details in [Immortus JavaScript section](js.md)

JS Verify
---

We use jQuery Promises for more details check [jQuery deferred API](http://api.jquery.com/category/deferred-object/)

##### Minimalistic

If you create some job and then redirect to a page where you need to know when it's finished or if you need to survive a refresh you could use:

```javascript
var jobFinished = function(data) {
  // Job was completed here. `data` has the info returned in `default verify`
  // i.e. data = { job_id: ... , completed: true }
  console.log(data.job_id + ' finished successfully.');
};

var jobFailed = function(data) {
  // Job was completed here. `data` has the info returned in `default verify`
  // i.e. data = {}
  console.log('error in job');
};

Immortus.verify({ job_id: '908ec6f1-e093-4943-b7a8-7c84eccfe417' })
        .then(jobFinished, jobFailed);
```

##### Intermediate

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

##### Explicit

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
  verifyJobUrl: '/job_custom_verify/908ec6f1-e093-4943-b7a8-7c84eccfe417'
};

var options = {
  longPolling: {
    interval: 800
  }
};

Immortus.verify(jobInfo, options)
        .then(jobFinished, jobFailed, jobInProgress);
```

For all the options check the details in [Immortus JavaScript section](js.md)
