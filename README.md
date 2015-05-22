Immortus
===

![Immortus](http://img1.wikia.nocookie.net/__cb20051217012058/marveldatabase/images/thumb/5/52/Nathaniel_Richards_%28Immortus%29_%28Earth-6311%29.jpg/250px-Nathaniel_Richards_%28Immortus%29_%28Earth-6311%29.jpg)

> The ruler of Limbo, Immortus bartered with the near-omnipotent Time-Keepers for immortality, in exchange becoming their agent in preserving timelines at all costs, no matter how many lives get disrupted, ruined, or erased.

### What Immortus do?

Immortus tracks ActiveJob job's status by employing a tracking strategy based on ActiveJob callbacks and lets you handle it on your UI through Javascript.

You can use one of our pre-implemented tracking strategy or create your own.

### When should I use Immortus

When you need to keep track of an async job. For example:

- send emails
- upload an image
- process an image
- import / export files ( .xls, .csv, ... )
- etc.

### Requirements

- Rails ( >= 4.0 )
- ActiveJob ( add `gem 'activejob_backport'` to Gemfile if 4.0 <= Rails < 4.2 )
- jQuery

### Installation

Add to your application's Gemfile:

```ruby
gem 'immortus'
```

And then execute:

    $ bundle

### Usage Example

##### Create job routes

```ruby
# config/routes.rb
Rails.application.routes.draw do
  immortus_jobs do
    post "generate_invoice", :to => "invoices#generate"
    # other routes to jobs may be added here

    # this will create under the hood
      # get '/immortus/verify/:job_id', :to => 'immortus#verify_job'
      # post '/generate_invoice', :to => 'invoices#generate'
      # other routes to jobs
  end
end
```

##### Controller

```ruby
# app/controllers/invoices_controller.rb
class InvoicesController < ApplicationController
  def generate
    job = GenerateInvoiceJob.perform_later
    render_immortus job

    # this will create under the hood
    #   if job.try('job_id')
    #     render json: { job_id: job.job_id, job_class: job.class }
    #   else
    #     render json: { error: "An error occurred enqueuing the job. #{job.error_exception}" }, status: 500
    #   end
  end
end
```

##### Switch Job parent class from `ActiveJob` to `Immortus::Job`

```ruby
# app/jobs/generate_invoice_job.rb
class GenerateInvoiceJob < ActiveJob
  def perform(record)
    # Generate invoices ...
  end
end
```

to

```ruby
# app/jobs/generate_invoice_job.rb
class GenerateInvoiceJob < Immortus::Job
  def perform(record)
    # Generate invoices ...
  end
end
```

`Immortus::Job` is still a subclass of `ActiveJob` so you can continue to use all the code that you could've used in a regular ActiveJob class.

```ruby
GenerateInvoiceJob.new.is_a?(ActiveJob) # => true
```

for more details check the [Immortus Job section](job.md)

##### Javascript

Require Immortus in your manifest file ( make sure jQuery is included at this point ):

```javascript
// in your main js file: usually assets/javascript/application.js

//= ...
//= require immortus
```

To create and track an async job call in your JS:

```javascript
var jobFinished = function(data) {
  // Job was completed here. `data` has the info returned in the `GenerateInvoicesController#verify`
  console.log(data.job_id ' finished successfully.');
}

var jobFailed = function(data) {
  console.log('error in job ' + data.job_id);
}

Immortus.create('/generate_invoice')
        .then(function(job_id) {
          return Immortus.verify({ job_id: job_id });
        })
        .then(jobFinished, jobFailed);
```

To only track an existing job without creating it:

```javascript
Immortus.verify({ job_id: '908ec6f1-e093-4943-b7a8-7c84eccfe417' })
        .then(jobFinished, jobFailed);
```

We use jQuery Promises (we can use .done or .fail instead of .then) for more details check [jQuery deferred API](http://api.jquery.com/category/deferred-object/)

for all the options check the details in [Immortus JavaScript section](js.md)

### Tracking Strategy

Immortus will use a strategy to keep track of the job status.

Tracking strategy order is perJob/Immortus::Job config/ActiveJob QueueAdapter infer

#### Inferred from ActiveJob queue adapter

By default it will infer the strategy from the ActiveJob queue adapter ( config.active_job.adapter )

Here is a list of the ActiveJob queue adapter and its mapped strategies:

| ActiveJob QueueAdapter |    Inferred Strategy    |                              Wiki                             |
|-----------------------:|:-----------------------:|:-------------------------------------------------------------:|
|           :delayed_job | :delayed\_job\_strategy | [How it works?](tracking_strategies.md#delayed-job-strategy)  |
|            :backburner |           N/A           |                              N/A                              |
|                    :qu |           N/A           |                              N/A                              |
|                   :que |           N/A           |                              N/A                              |
|         :queue_classic |           N/A           |                              N/A                              |
|               :sidekiq |           N/A           |                              N/A                              |
|              :sneakers |           N/A           |                              N/A                              |
|          :sucker_punch |           N/A           |                              N/A                              |
|                :inline |           N/A           |                              N/A                              |
|                  :test |           N/A           |                              N/A                              |

#### Override the default strategy

```ruby
# config/initializer/immortus.rb
Immortus::Job.tracking_strategy = :redis_pub_sub_strategy
```
#### Define the tracking strategy per job

By default all `Immortus::Job` subclasses will inherit the default tracking strategy but you can define it in a per job basis

```ruby
# app/jobs/generate_invoice_job.rb
class GenerateInvoiceJob < Immortus::Job
  tracking_strategy :redis_pub_sub_strategy

  def perform(record)
    # Generate invoices ...
  end
end
```

#### Define your own tracking strategy

```ruby
# app/jobs/tracking_strategy/my_custom_tracking_strategy.rb
module TrackingStrategy
  class MyCustomTrackingStrategy

    def job_enqueued(job_id)
      # Save in a custom table that this job was created
      MyCustomTrackingJobTable.create!(job_id: job_id, status: 'created')
    end

    def job_started(job_id)
      find(job_id).update_attributes(status: 'started')
    end

    def job_finished(job_id)
      job = find(job_id)
      job.update_attributes(status: 'finished')
    end

    def completed?(job_id)
      # completed? method is mandatory, should return a boolean ( true if job is finished, false otherwise )
      job = find(job_id)
      job.status == 'finished'
    end

    def meta(job_id)
      # if meta method is defined, the returned hash will be added in every verify request
      job = find(job_id)

      {
        last_error: job.last_error,
        attempts: job.attempts
      }
    end

    private

    def find(job_id)
      MyCustomTrackingJobTable.find_by(job_id: job_id)
    end
  end
end

# config/initializer/immortus.rb
Immortus::Job.tracking_strategy = :my_custom_tracking_strategy
# you could also specify the class directly:
# Immortus::Job.tracking_strategy = TrackingStrategy::MyCustomTrackingStrategy
```

for more details check the [Custom Tracking Strategies section](tracking_strategies.md#custom-strategy)

You can use Immortus in almost any case
---

let's use it to update a percentage of a big background job

##### Create job routes

```ruby
# config/routes.rb
Rails.application.routes.draw do
  # ...

  immortus_jobs do
    post "generate_big_background_job", :to => "big_background_job#generate"
  end
end
```

##### Controller

```ruby
# app/controllers/big_background_job_controller.rb
class BigBackgroundJobController < ApplicationController
  def generate
    job = BigBackgroundJob.perform_later

    render_immortus job
  end
end
```

```ruby
# app/jobs/tracking_strategy/big_background_job_strategy.rb
module TrackingStrategy
  class BigBackgroundJobStrategy

    def job_enqueued(job_id)
      # Save in a custom table that this job was created
      BigBackgroundJobTable.create!(job_id: job_id, status: 'enqueued', percentage: 0)
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
      BigBackgroundJobTable.find_by(job_id: job_id)
    end

  end
end
```

##### create `Immortus::Job` with our custom strategy

```ruby
# app/jobs/big_background_job.rb
class BigBackgroundJob < Immortus::Job
  tracking_strategy :big_background_job_strategy

  def perform(record)
    # do some heavy processing ...
    # update job percentage by using:
    #   self.strategy.update_percentage(job_id, percentage)
  end
end
```

##### Javascript

To create and track an async job call in your JS:

```javascript
var jobCreatedSuccessfully = function(data) {
  // logic to add some loading gif

  return data.job_id;
}

var jobFailedToCreate = function() {
  alert('Job failed to create');
}

var jobFinished = function(data) {
  // logic to finish ...
}

var jobFailed = function(data) {
  alert('Job ' + data.job_id + ' failed to perform');
}

var jobInProgress = function(data) {
  // logic to update percentage with `data.percentage` ...
}

Immortus.create('/generate_big_background_job')
        .then(jobCreatedSuccessfully, jobFailedToCreate)
        .then(function(job_id) {
          return Immortus.verify({ job_id: job_id }, { longPolling: { interval: 5000 } });
        })
        .then(jobFinished, jobFailed, jobInProgress);
```

To only track an existing job without creating it:

```javascript
// render_immortus returns the job_class. in this case since we don't use the create job we need to pass the jobClass manually
Immortus.verify({ job_id: '908ec6f1-e093-4943-b7a8-7c84eccfe417', job_class: 'big_background_job' }, { longPolling: { interval: 5000 } })
        .then(jobFinished, jobFailed, jobInProgress);
```

Development
---

For test with guard

    $ bundle exec guard

Contributing
---

1. Fork it ( https://github.com/runtime-revolution/immortus/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

Credits
---
![Runtime Revolution](https://pbs.twimg.com/profile_images/569571806634196992/GU3JsMP4.png)
[Runtime Revolution](http://www.runtime-revolution.com/)

ROADMAP
---

0.1

- [x] Initial Specs
    - [x] Immortus controller
    - [x] Immortus::StrategyFinder
    - [x] Immortus::Job callbacks
    - [x] Tracking Strategies
        - [x] Delayed Job (AR)
- [x] Build Initial Version
    - [x] Routes DSL ( immortus_jobs )
    - [x] JS ( Immortus.perform )
    - [x] JS ( Immortus.verify )
    - [x] JS ( Immortus long polling )
    - [x] Render ( render_immortus )
    - [x] ImmortusController#verify
        - [x] Tracking Strategies
            - [x] Delayed Job ( AR )
- [ ] Define Immortus::Job Strategy interface and expected return values
    - [ ] Wiki explaining on how inferred strategies work
- [ ] Define Immortus.JS interface for handling successful and error responses
    - [ ] `beforeSend`, `afterEnqueue`, `completed` callbacks  function arguments defenition
        - [ ] Will it be able for `completed` to have a flag `success` or not? How should this work if possible?
- [ ] How `Immortus.perform` and `Immortus.verify` handle if AJAX requests returns an error ( 404/500/etc ) -> error(job_id, status, meta)
- [ ] Rewrite what render_immortus(job) does under the hood in the README
- [x] Use a consistent specs/tests syntax
- [ ] Setup testing environment to work with different Ruby versions and Rails versions

1.0

- [ ] Specs
    - [ ] render_immortus
    - [ ] Tracking Strategies
        - [ ] Backburner
        - [ ] Qu
        - [ ] Que
        - [ ] queue_classic
        - [ ] Resque
        - [ ] Sidekiq
        - [ ] Sneakers
        - [ ] Sucker Punch
        - [ ] Active Job Inline
- [ ] LOGS
- [ ] Tracking Strategies
    - [ ] Backburner
    - [ ] Qu
    - [ ] Que
    - [ ] queue_classic
    - [ ] Resque
    - [ ] Sidekiq
    - [ ] Sneakers
    - [ ] Sucker Punch
    - [ ] Active Job Inline

1.1

- [ ] Remove jQuery dependency ( ajax request using xmlhttp )
- [ ] Error handling: http://www.sitepoint.com/dont-get-activejob/
- [ ] progress bar?: https://www.infinum.co/the-capsized-eight/articles/progress-bar-in-rails
- [ ] How to handle jobs that are divided into multiple sub-jobs

Later

- [ ] WebSockets support
    - [ ] ActionCable support
- [ ] Remove ActiveJob dependency ( support using Backends directly "Delayed Job", "Sidekiq", etc )
- [ ] Remove Rails dependency
- [ ] Config Inline Immortus::Job Strategy
    - [ ] Change Router DSL to support specify verify url
