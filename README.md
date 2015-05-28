Immortus
===

![Immortus](http://img1.wikia.nocookie.net/__cb20051217012058/marveldatabase/images/thumb/5/52/Nathaniel_Richards_%28Immortus%29_%28Earth-6311%29.jpg/250px-Nathaniel_Richards_%28Immortus%29_%28Earth-6311%29.jpg)

> The ruler of Limbo, Immortus bartered with the near-omnipotent Time-Keepers for immortality, in exchange becoming their agent in preserving timelines at all costs, no matter how many lives get disrupted, ruined, or erased.

### What Immortus do?

Immortus tracks ActiveJob job's status by employing a tracking strategy based on ActiveJob callbacks and lets you handle it on your UI through Javascript.

You can use one of our pre-implemented tracking strategy or create your own.

Currently Immortus uses Long Polling to verify job status.

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

#### Installation

Add to your application's Gemfile:

```ruby
gem 'immortus'
```

And then execute:

```
$ bundle
```

### Tracking Strategy

Immortus will use a tracking strategy to keep track of the job status.

1. If the Job has defined an [Inline Tracking Strategy](./docs/tracking_strategies.md) it will use it.
2. If not it will use the [User Global Configured](./docs/tracking_strategies.md) if defined
3. Otherwise it will [inferred from the ActiveJob Queue Adapter](./docs/tracking_strategies.md)

You can see how this work in more detail [here](./docs/tracking_strategies.md)

### Example usage

Let's say we want to:

* Create an Invoice by AJAX
* Invoice will be created asynchronously because it's a long running task
* Notify in the UI when that invoice was created.

```javascript
// Require Immortus in your Manifest ( make sure jQuery is included at this point ):

//= ...
//= require immortus
```

```javascript
$('.create-invoice-form').on('submit', function(e) {
  e.preventDefault();

  var jobFinished = function(data) { console.log(data.job_id + ' finished successfully.'); }
  var jobFailed = function(data) { console.log('error in job ' + data.job_id); }

  Immortus.create('/generate_invoice')
          .done(function (data) {
            return Immortus.verify({ jobId: data.job_id })
                           .then(jobFinished, jobFailed);
          });
});
```

```ruby
# config/routes.rb
Rails.application.routes.draw do
  # Add the routes for the job creation and check status
  immortus_jobs do
    post 'generate_invoice', to: 'invoices#generate'
  end
end

# app/controllers/invoices_controller.rb
class InvoicesController < ApplicationController
  def generate
    job = GenerateInvoiceJob.perform_later
    render_immortus(job)
  end
end

# app/jobs/generate_invoice_job.rb
class GenerateInvoiceJob < ActiveJob::Base
  # Include Immortus::Job in your new or existing ActiveJob class
  include Immortus::Job

  def perform(*args)
    # ...
  end
end
```

### Full documentation

For a full documentation on how this works please check:

* [Javascript](./docs/full.md#javascript)
* [Routes](./docs/full.md#routes)
* [Controller](./docs/full.md#controller)
* [Immortus::Job](./docs/full.md#immortus_job)

### Some more advanced examples

By allowing [custom strategies](./docs/tracking_strategies.md#custom) and [custom verify controllers](./docs/full.md#controller) Immortus can be used for more complex work. Just a few examples:

* [Track a job progress and update that progress in the UI](./docs/examples/job_progress.md)
* TODO: Add more examples here









----


To only track an existing job without creating it:

```javascript
Immortus.verify({ job_id: '908ec6f1-e093-4943-b7a8-7c84eccfe417' })
        .then(jobFinished, jobFailed);
```



----





-----

```ruby
# config/routes.rb
Rails.application.routes.draw do
  immortus_jobs do
    get  "job_custom_verify/:job_id", :to => "job_custom_verify#verify"
  end
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

------




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

![Runtime Revolution](http://lh3.googleusercontent.com/-iRjFzclpFKg/AAAAAAAAAAI/AAAAAAAAABk/aVVbuMI11WA/s265-c-k-no/photo.jpg)
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
