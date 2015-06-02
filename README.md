Immortus
===

![Immortus](./docs/Immortus.jpg)

> The ruler of Limbo, Immortus bartered with the near-omnipotent Time-Keepers for immortality, in exchange becoming their agent in preserving timelines at all costs, no matter how many lives get disrupted, ruined, or erased.

### What does Immortus do

`Immortus` tracks ActiveJob jobs statuses and lets you handle them on your UI through Javascript callbacks.

Currently `Immortus` uses Long Polling to verify job status. Web Sockets support is on the [ROADMAP](./docs/ROADMAP.md).

### When should I use Immortus

When you need to keep track of an async job.
For example:

- send emails
- upload / process an image
- import / export files ( .xls, .csv, ... )
- etc.

### How does Immortus work

`Immortus` will use a tracking strategy, based on ActiveJob callbacks, to keep track of the jobs statuses.

By default, tracking strategy will be inferred from ActiveJob Queue Adapter, but we know that you may need more complexity so we let you create your own!

You can see how tracking strategies work in more detail [here](./docs/tracking_strategies.md)

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

#### Setup

```javascript
// Require Immortus in your Manifest ( make sure jQuery is included at this point ):

//= ...
//= require immortus
```

### Example usage

##### track a job

Let's say we want to:

* Track an Invoice job (job is already created somewhere in your code)
* Notify in the UI when that invoice was created

```javascript
$('.js-track-invoice').each(function() {
  Immortus.verify({ job_id: $(this).data('job-id') })
          .then(function(data) { console.log(data.job_id + ' finished successfully.'); });
});
```

```ruby
# config/routes.rb
Rails.application.routes.draw do
  # Add the routes for check status
  immortus_jobs
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

##### create and track a job

Let's say we want to:

* Create an Invoice by AJAX
* Invoice will be created asynchronously because it's a long running task
* Notify in the UI when that invoice was created

```javascript
$('.js-create-invoice').click(function() {
  Immortus.create('/generate_invoice')
          .then(function (jobInfo) {
            return Immortus.verify({ job_id: jobInfo.job_id })
                           .then(function(data) { console.log(data.job_id + ' finished successfully.'); });
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
* [Immortus::Job](./docs/full.md#immortus-job)

### Some more advanced examples

By allowing [custom strategies](./docs/tracking_strategies.md#define-a-custom-tracking-strategy) and [custom verify controllers](./docs/full.md#how-to-create-a-custom-verify) Immortus can be used for more complex work. Just a few examples:

* [Create a Job and track progress](./docs/examples/intermediate.md)
* [Create a Job and track progress with custom verify](./docs/examples/explicit.md)
* [Track a job progress and update percentage in the UI](./docs/examples/job_progress.md)
* TODO: Add more examples here

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

License
---

Copyright © 2015 [Runtime Revolution](http://www.runtime-revolution.com/), released under the MIT license.

You are not granted rights or licenses to the trademarks of Runtime Revolution

[![Runtime Revolution](./docs/runtime-revolution-logo.png)](http://www.runtime-revolution.com/)
