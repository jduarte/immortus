Immortus
===

![Immortus](http://img1.wikia.nocookie.net/__cb20051217012058/marveldatabase/images/thumb/5/52/Nathaniel_Richards_%28Immortus%29_%28Earth-6311%29.jpg/250px-Nathaniel_Richards_%28Immortus%29_%28Earth-6311%29.jpg)

> The ruler of Limbo, Immortus bartered with the near-omnipotent Time-Keepers for immortality, in exchange becoming their agent in preserving timelines at all costs, no matter how many lives get disrupted, ruined, or erased.

### What Immortus do?

Immortus tracks ActiveJob job's status by employing a tracking strategy based on ActiveJob callbacks and lets you handle it on your UI through Javascript.

You can use one of our pre-implemented tracking strategy or create your own.

Currently `Immortus` uses Long Polling to verify job status.

### When should I use Immortus

When you need to keep track of an async job.
For example:

- send emails
- upload / process an image
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
    post 'generate_invoice', to: 'invoices#generate'
    # other routes to jobs may be added here

    # `immortus_jobs` will create under the hood
    #   get '/immortus/verify/:job_id(/:job_class)', to: 'immortus#verify'
    #   post '/generate_invoice', :to => 'invoices#generate'
    #   other routes to jobs
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

    # `render_immortus` will create under the hood
    #   if job.try('job_id')
    #     render json: { job_id: job.job_id, job_class: job.class.name }
    #   else
    #     render json: {}, status: 500
    #   end
  end
end
```

##### include `Immortus::Job` in your `ActiveJob` or create a new ActiveJob

```ruby
# app/jobs/generate_invoice_job.rb
class GenerateInvoiceJob < ActiveJob::Base
  include Immortus::Job

  def perform(*args)
    # Generate invoices ...
  end
end
```

##### Javascript

Require `Immortus` in your manifest file ( make sure jQuery is included at this point ):

```javascript
//= ...
//= require immortus
```

To create and track an async job call in your JS:

```javascript
var jobFinished = function (data) {
  // Job was completed here.
  console.log(data.job_id + ' finished successfully.');
};

var jobFailed = function (data) {
  console.log('error in job ' + data.job_id);
};

Immortus.create('/generate_invoice')
        .then(function (data) {
          return Immortus.verify({ jobId: data.job_id })
                         .then(jobFinished, jobFailed);
        });
```

To only track an existing job without creating it:

```javascript
Immortus.verify({ job_id: '908ec6f1-e093-4943-b7a8-7c84eccfe417' })
        .then(jobFinished, jobFailed);
```

We use jQuery Promises (we can use .done or .fail instead of .then) for more details check [jQuery deferred API](http://api.jquery.com/category/deferred-object/)

for all the options check the details in [Immortus JavaScript section](js.md)

To see more examples check [Examples section](examples.md)

To see detailed version check [Details section](./docs/details.md)

### Tracking Strategy

`Immortus` will use a strategy to keep track of the job status.

Tracking strategy order is perJob/Immortus::Job config/ActiveJob QueueAdapter infer

for more details check the [Tracking Strategies section](tracking_strategies.md)

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

#### Override the default strategy

```ruby
# config/initializer/immortus.rb
Immortus::Job.tracking_strategy = :redis_pub_sub_strategy
```
#### Define the tracking strategy per job

By default all `Immortus::Job` subclasses will inherit the default tracking strategy but you can define it in a per job basis

```ruby
# app/jobs/generate_invoice_job.rb
class GenerateInvoiceJob < ActiveJob::Base
  include Immortus::Job

  tracking_strategy :redis_pub_sub_strategy

  def perform(*args)
    # Generate invoices ...
  end
end
```

#### Define your own tracking strategy with default verify controller

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

    # completed? method is mandatory, should return a boolean ( true if job is finished, false otherwise )
    def completed?(job_id)
      job = find(job_id)
      job.status == 'finished'
    end

    # if meta method is defined, the returned hash will be added in every verify request
    def meta(job_id)
      job = find(job_id)

      {
        status: job.status
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

#### Define your own tracking strategy with custom verify controller

you could define a custom controller to better fit your custom strategy

```ruby
# config/routes.rb
Rails.application.routes.draw do
  # ...

  get  "job_custom_verify/:job_id", :to => "job_custom_verify#verify"
end
```

```ruby
# app/controllers/job_custom_verify_controller.rb
class JobCustomVerifyController < ApplicationController
  def verify
    strategy = JobCustomVerify.strategy

    # returned `json` will be available in `data` within JS callbacks
    # `completed` should be one of returned `json` parameters

    render json: {
      :completed => strategy.completed?(params[:job_id]),
      :percentage => strategy.percentage(params[:job_id])
    }
  end
end
```

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

for more details check the [Custom Tracking Strategies section](tracking_strategies.md#custom-strategy)

To see detailed version check [Details section](./docs/details.md)

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

![Runtime Revolution](https://avatars1.githubusercontent.com/u/60465?v=3&s=200)
[Runtime Revolution](http://www.runtime-revolution.com/)

ROADMAP
---

#### 0.0.1

- [x] Tests
- [x] Routes DSL ( immortus_jobs )
- [x] Immortus JS ( long polling )
- [x] Default verify ( ImmortusController#verify )
- [x] Tracking Strategies
    - [x] Delayed Job ( AR )

#### Soon

- [ ] Setup testing environment to work with different Ruby versions and Rails versions
- [ ] Tests
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
- [ ] Ensure JS callbacks `data` is available
- [ ] LOGS

#### Future Developments

- [ ] Error handling: http://www.sitepoint.com/dont-get-activejob/
- [ ] How to handle jobs that are divided into multiple sub-jobs
- [ ] WebSockets support
    - [ ] ActionCable support
- [ ] Consider remove ActiveJob dependency ( support using Backends directly "Delayed Job", "Sidekiq", etc )
- [ ] Consider remove Rails dependency
