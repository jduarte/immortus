Immortus
===

![Immortus](http://img1.wikia.nocookie.net/__cb20051217012058/marveldatabase/images/thumb/5/52/Nathaniel_Richards_%28Immortus%29_%28Earth-6311%29.jpg/250px-Nathaniel_Richards_%28Immortus%29_%28Earth-6311%29.jpg)

> The ruler of Limbo, Immortus bartered with the near-omnipotent Time-Keepers for immortality, in exchange becoming their agent in preserving timelines at all costs, no matter how many lives get disrupted, ruined, or erased.

### When should I use Immortus

Anytime you need to keep track of an async job, like:

- send emails
- upload or process an image
- import / export files ( .xls, .csv, ... )
- etc

### What Immortus do?

This gem will do all the work (currently using long polling) to update status of a job,
it has some JS callback so you can specify what should be done in UI when status is changed.

You just need to create the **Immortus::Job** (or update any **ActiveJob** to **Immortus::Job**), add the route (and it's controller/action) and specify what should be done in each state (we don't do any UI).
For more details see [usage](#usage)

Requirements
---

- Rails
- ActiveJob gem:
  - `gem 'activejob'` if rails >= 4.2
  - `gem 'activejob_backport'` and it's initializer if rails >= 4.0 and < 4.2
- jQuery

Installation
---

Add this line to your application's Gemfile:

```ruby
gem 'immortus'
```

And then execute:

    $ bundle

Usage
---

### JS for Long Polling
add to your JS file:
```javascript
// jQuery should be setted before this line
//= require immortus
```

### Example / Use Case

Add the jobs routes at your Rails application routes file:

```ruby
Rails.application.routes.draw do
  immortus_jobs do
    post 'generate_invoice', to: 'invoices#generate', as: :generate_invoice
    # other routes to jobs may be added here
  end
end
```
> This will create under the hood:
```ruby
get '/immortus/verify/:job_id', to: 'immortus#verify_job', as: :verify_immortus_job
post '/generate_invoice', to: 'invoices#generate', as: :generate_invoice
# other routes to jobs ...
```

You should create your controller in ...

```ruby
class InvoicesController < ApplicationController
  def generate
    job = GenerateInvoiceJob.perform_later

    render_immortus job
  end
end
```
> 'render_immortus' under the hoods is doing:
```ruby
if job.enqueued?
  render json: { job_id: job.job_id }
else
  render json: { error: "An error occurred enqueing the job. #{job.error_exception}" }, status: 500
end
```

Where you previously have an ActiveJob call

```ruby
# app/jobs/generate_invoice_job.rb
class GenerateInvoiceJob < ActiveJob
  def perform(record)
  # Generate invoices ...
  end
end
```

.. call an Immortus::Job

```ruby
# app/jobs/generate_invoice_job.rb
class GenerateInvoiceJob < Immortus::Job
  def perform(record)
  # Generate invoices ...
  end
end
```

**Immortus** will have a default strategy based on the ActiveJob adapter that's being used ( config.active_job.adapter )

- **:delayed_job** => Immortus::TrackingStrategy::DelayedJobStrategy (uses Delayed Job Table)

TODO: Add more default tracking strategies for ActiveJob adapters later, like:

- **:resque** => Immortus::TrackingStrategy::RedisPubSubStrategy ( saves to Redis when job is created and then deletes it when it's finished )



You can always override the default strategy if you'd like:

```ruby
# config/initializer/immortus.rb
Immortus::Job.tracking_strategy = Immortus::TrackingStrategy::RedisPubSubStrategy
```

You can define your own persistence strategy if you'd like:

```ruby
# app/jobs/tracking_strategy/my_custom_tracking_strategy.rb
module TrackingStrategy
  class MyCustomTrackingStrategy
    def find(job_id)
      MyCustomTrackingJobTable.find_by(job_id: job_id)
    end

    def job_enqueued(job_id)
      # Save somewhere that this job was created
      MyCustomTrackingJobTable.create! job_id: job_id, status: 'created'
    end

    def job_started(job_id)
      find(job_id).update_attributes(status: 'started')
    end

    def status(job_id)
      # Ensure you return one of 4 status
      # :created => 'Job was created but wasnt started yet'
      # :started => 'Job was started'
      # :finished_error => 'An error occurred running the job'
      # :finished_success => 'Job was finished'

      tracker = find(job_id)
      tracker.status.to_sym
    end

    def job_finished(job_id)
      tracker = find(job_id)
      tracker.destroy
    end
  end
end

# config/application.rb
Rails::Application.configuration do |config|
  # ...
  config.immortus.tracking_strategy = :my_custom_tracking_strategy
  # you could also specify the class, it's mandatory if namespaced, like:
  # config.immortus.tracking_strategy = MyApp::SomeOtherModule::MyCustomStrategy
end
```

Then call it from whenever you want from your Javascript:

```javascript
var showLoadingIcon = function() {
  // called at the beginning of Immortus.perform
}

var checkIfJobWasStarted = function(job_id, enqueue_successfull) {
  // called at the end of Immortus.perform
  // if (!enqueue_successfull) { no long pooling is done and job_id is undefined }
}

var removeLoadingIcon = function(job_id, successfull) {
  // Handle success or error
  // No more long pooling
}

Immortus.perform({
  url: '/generate_invoice',
  longpolling: {
    interval: 1000
  },
  beforeSend: showLoadingIcon,
  afterEnqueue: checkIfJobWasStarted,
  completed: removeLoadingIcon
});
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

- [X] Initial Specs
  - [X] Immortus controller
  - [X] Immortus::StrategyFinder
  - [X] Immortus::Job callbacks
  - [X] Tracking Strategies
    - [X] Delayed Job (AR)
- [X] Build Initial Version
  - [X] Routes DSL ( immortus_jobs )
  - [X] JS ( Immortus.perform )
  - [X] JS ( Immortus.verify )
  - [X] JS ( Immortus long polling )
  - [X] Render ( render_immortus )
  - [X] ImmortusController#verify
    - [X] Tracking Strategies
      - [X] Delayed Job ( AR )

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

WIKI
---

### Create job endpoint

The create job endpoint must return a JSON of the following type:

The **Immortus** JS will use promises internally to perform the AJAX requests. As so 2xx status code in the responses are considered success and other ones are considered fails.

In the case of a successful response, the JSON object must have the following structure:

```json
{
  "job_id": "908ec6f1-e093-4943-b7a8-7c84eccfe417"
}
```

In the case where an error ocurred enqueuing the job, the JSON object should have the following structure:

```json
{
  "error": "Error description why this job failed to enqueue"
}
```

We usually use job_id as a GUID in order to avoid collisions. Anyway the only thing you must ensure is that each job ID is unique.

### Verify job (what is done behind the scene)

TODO: Detail Verify job

### JS

To create and track a new job:

```javascript
Immortus.perform({
  url: '/generate_invoice',
  longpolling: {
    interval: 1000
  },
  beforeSend: function() {
    // executed before ajax request
  },
  afterEnqueue: function(job_id, enqueue_successfull) {
    // executed after ajax request
  },
  completed: function(job_id, successfull) {
    // executed when job is completed
  }
});
```

To track an existing job:

```javascript
Immortus.verify({
  job_id: '908ec6f1-e093-4943-b7a8-7c84eccfe417',
  longpolling: {
    interval: 1000
  },
  setup: function() {
    // executed before the first verify ajax request
  },
  completed: function(successfull) {
    // executed when job is completed
  }
});
```
