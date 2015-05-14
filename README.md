Immortus
===

![Immortus](http://img1.wikia.nocookie.net/__cb20051217012058/marveldatabase/images/thumb/5/52/Nathaniel_Richards_%28Immortus%29_%28Earth-6311%29.jpg/250px-Nathaniel_Richards_%28Immortus%29_%28Earth-6311%29.jpg)

> The ruler of Limbo, Immortus bartered with the near-omnipotent Time-Keepers for immortality, in exchange becoming their agent in preserving timelines at all costs, no matter how many lives get disrupted, ruined, or erased.

### When should I use Immortus

Anytime you need to keep track of an async job, like:
- send emails
- upload or process an image
- export .xls or .csv
- etc

### What Immortus do?

This gem will do all the work (currently using long polling) to update status of a job,
it has some JS callback so you can specify what should be done in UI when status is changed.

You just need to create the **Immortus::Job** (or update any **ActiveJob** to **Immortus::Job**), add the route (and it's controller/action) and specify what should be done in each state (we don't do any UI).
For more details see [usage](#usage)

Requirements
---

* Rails
* ActiveJob gem: `gem 'activejob'` if rails >= 4.2 or `gem 'activejob_backport'` if rails >= 4.0 and < 4.2
* jQuery

### ActiveJob Backends Features
```
                    | Async | Queues | Delayed   | Priorities | Timeout | Retries |
|-------------------|-------|--------|-----------|------------|---------|---------|
| Backburner        | Yes   | Yes    | Yes       | Yes        | Job     | Global  |
| Delayed Job       | Yes   | Yes    | Yes       | Job        | Global  | Global  |
| Qu                | Yes   | Yes    | No        | No         | No      | Global  |
| Que               | Yes   | Yes    | Yes       | Job        | No      | Job     |
| queue_classic     | Yes   | Yes    | No*       | No         | No      | No      |
| Resque            | Yes   | Yes    | Yes (Gem) | Queue      | Global  | Yes     |
| Sidekiq           | Yes   | Yes    | Yes       | Queue      | No      | Job     |
| Sneakers          | Yes   | Yes    | No        | Queue      | Queue   | No      |
| Sucker Punch      | Yes   | Yes    | No        | No         | No      | No      |
| Active Job Inline | No    | Yes    | N/A       | N/A        | N/A     | N/A     |
| Active Job        | Yes   | Yes    | Yes       | No         | No      | No      |
```
[more info](http://api.rubyonrails.org/classes/ActiveJob/QueueAdapters.html#module-ActiveJob::QueueAdapters-label-Backends+Features)

We can only track jobs that are persisted, so we can only support Backends that have that Feature (Delayed?)

Installation
---

Add this line to your application's Gemfile:

```ruby
gem 'immortus'
```

And then execute:

    $ bundle

<!--
Or install it yourself as:

    $ gem install immortus
-->

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
> ```ruby
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
> ```ruby
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
# config/application.rb
Rails::Application.configuration do |config|
  # ...
  config.immortus.tracking_strategy = Immortus::TrackingStrategy::RedisPubSubStrategy
end
```

You can define your own persistence strategy if you'd like:

```ruby
# app/jobs/tracking_strategies/my_custom_tracking_strategy.rb
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
Immortus.perform({
  url: '/generate_invoice',
  longpolling: {
    interval: 1000
  },
  beforeSend: showRedCog,
  afterEnqueue: showYellowCog,
  completed: showSuccessOrErrorIcon
});
```

We assume `showSuccessOrErrorIcon`, `showRedCog` and `showYellowCog` are javascript functions with logic to handle each situation

<!--
Development
---

After checking out the repo, run `bin/setup` to install dependencies. Then, run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release` to create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

    $ appraisal rake test

    $ bundle exec guard
-->

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

1.0
- [ ] Specs
  - [X] Immortus controller
  - [X] Immortus::StrategyFinder
  - [X] Immortus::Job callbacks
  - [ ] render_immortus
  - [ ] Tracking Strategies
- [ ] Build Initial Version
  - [X] Routes DSL (immortus_jobs)
  - [X] JS (Immortus.perform)
  - [X] JS (Immortus long polling)
  - [X] Render (render_immortus)
    - [ ] successfully enqueued?
  - [X] ImmortusController#verify
    - [ ] build strategies to support all ActiveJob adapters
      - [X] Delayed Job
      - [ ] Backburner
      - [ ] Qu
      - [ ] Que
      - [ ] queue_classic
      - [ ] Resque
      - [ ] Sidekiq
      - [ ] Sneakers
      - [ ] Sucker Punch
      - [ ] Active Job Inline
    - [ ] check job status
- [ ] Review README.md
- [ ] Release

1.1
- [X] JS ( Immortus.verify )
- [ ] Keep track even after a refresh

1.2
- [ ] Remove jQuery dependency (ajax request using xmlhttp)
- [ ] Error handling: http://www.sitepoint.com/dont-get-activejob/
- [ ] progress bar?: https://www.infinum.co/the-capsized-eight/articles/progress-bar-in-rails
- [ ] How to handle jobs that are divided into multiple sub-jobs

Later
- [ ] WebSockets support
- [ ] ActionCable support
- [ ] Remove ActiveJob dependency (support using Backends directly "Delayed Job", "Sidekiq", etc)
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
  completed: function(successfull) {
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
