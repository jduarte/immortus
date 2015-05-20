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
    post "generate_invoice", :to => "invoices#generate", :as => :generate_invoice
    # other routes to jobs may be added here

    # this will create under the hood
      # get '/immortus/verify/:job_id', :to => 'immortus#verify_job', :as => :verify_immortus_job
      # post '/generate_invoice', :to => 'invoices#generate', :as => :generate_invoice
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
    #     render json: { job_id: job.job_id }
    #   else
    #     render json: { error: "An error occurred enqueing the job. #{job.error_exception}" }, status: 500
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

##### Javascript

Require Immortus in your manifest file ( make sure jQuery is included at this point ):

```javascript
// in your main js file: usually assets/javascript/application.js

//= ...
//= require immortus
```

To create and track an async job call in your JS:

```javascript
var logBeforeSend = function() { console.log('executed before AJAX request'); }
var logAfterEnqueue = function(job_id, enqueue_successfull) { console.log('job was enqueued'); }
var logCompleted = function(job_id, successfull) { console.log('job ' + job_id + 'was finished with ' + (successfull ? 'success' : 'error')); }

Immortus.perform({
  url: '/generate_invoice',
  longpolling: {
    interval: 2000,               // Defaults to 1000
  },
  beforeSend: logBeforeSend,      // Defaults to empty function
  afterEnqueue: logAfterEnqueue,  // Defaults to empty function
  completed: logCompleted         // Defaults to empty function
});
```

To only track an existing job without creating it:

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

### Tracking Strategy

Immortus will use a strategy to keep track of the job status

#### Inferred from ActiveJob queue adapter

By default it will infer the strategy from the ActiveJob queue adapter ( config.active_job.adapter )

Here is a list of the ActiveJob queue adapter and its mapped strategies:

| ActiveJob QueueAdapter |    Inferred Strategy    |                         Wiki                        |
|-----------------------:|:-----------------------:|:---------------------------------------------------:|
|           :delayed_job | :delayed\_job\_strategy | [How it works?](http://www.runtime-revolution.com/) |
|            :backburner |           N/A           |                         N/A                         |
|                    :qu |           N/A           |                         N/A                         |
|                   :que |           N/A           |                         N/A                         |
|         :queue_classic |           N/A           |                         N/A                         |
|               :sidekiq |           N/A           |                         N/A                         |
|              :sneakers |           N/A           |                         N/A                         |
|          :sucker_punch |           N/A           |                         N/A                         |
|                :inline |           N/A           |                         N/A                         |
|                  :test |           N/A           |                         N/A                         |

#### Override the default strategy

```ruby
# config/initializer/immortus.rb
Immortus::Job.tracking_strategy = :redis_pub_sub_strategy
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

    def status(job_id)
      # Ensure you return one of 3 poosible statuses
        # :created => Job was created but wasn't started yet
        # :started => Job was started
        # :finished => Job was finished

      job = find(job_id)
      job.status.to_sym
    end

    private

    def find(job_id)
      MyCustomTrackingJobTable.find_by(job_id: job_id)
    end
  end
end

# config/initializer/immortus.rb
Immortus::Job.tracking_strategy = :my_custom_tracking_strategy
# you could also specify the class, it's mandatory if namespaced, like:
# Immortus::Job.tracking_strategy = TrackingStrategy::MyCustomTrackingStrategy
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
- [ ] Define Immortus::Job Strategy interface and expected return values
    - [ ] Wiki explaining on how inferred strategies work
- [ ] Define Immortus.JS interface for handling successful and error responses
    - [ ] `beforeSend`, `afterEnqueue`, `completed` callbacks  function arguments defenition
        - [ ] Will it be able for `completed` to have a flag `success` or not? How should this work if possible?
- [ ] Rewrite what render_immortus(job) does under the hood in the README
- [ ] Setup testing environment to work with different Ruby versions and Rails versions
- [ ] How `Immortus.perform` and `Immortus.verify` handle if AJAX requests returns an error ( 404/500/etc )
- [ ] ImmortusController#verify seems to be duplicating info with `completed` and `success` in the response JSON
- [X] Use a consistent specs/tests syntax

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
