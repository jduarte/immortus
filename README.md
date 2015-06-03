Immortus
===

[![Gem Version](https://badge.fury.io/rb/immortus.svg)](http://badge.fury.io/rb/immortus)
[![Build Status](https://travis-ci.org/runtimerevolution/immortus.svg?branch=master)](https://travis-ci.org/runtimerevolution/immortus)
[![Code Climate](https://codeclimate.com/github/runtimerevolution/immortus/badges/gpa.svg)](https://codeclimate.com/github/runtimerevolution/immortus)
[![Dependency Status](https://gemnasium.com/runtimerevolution/immortus.svg)](https://gemnasium.com/runtimerevolution/immortus)
[![security](https://hakiri.io/github/runtimerevolution/immortus/master.svg)](https://hakiri.io/github/runtimerevolution/immortus/master)
[![Coverage Status](https://coveralls.io/repos/runtimerevolution/immortus/badge.svg)](https://coveralls.io/r/runtimerevolution/immortus)

![Immortus](./docs/Immortus.jpg)

> The ruler of Limbo, Immortus bartered with the near-omnipotent Time-Keepers for immortality, in exchange becoming their agent in preserving timelines at all costs, no matter how many lives get disrupted, ruined, or erased.

### What does Immortus do

`Immortus` tracks ActiveJob jobs statuses and lets you handle them on your UI through JavaScript callbacks.

Currently `Immortus` uses Polling to verify job status. Web Sockets support is on the [ROADMAP](./docs/ROADMAP.md).

### When should I use Immortus

When you need to keep track of an async job.
For example:

* send emails
* upload / process an image
* import / export files ( .xls, .csv, ... )
* etc.

### How does Immortus work

`Immortus` will use a tracking strategy, based on ActiveJob callbacks, to keep track of the jobs statuses.

By default, tracking strategy will be inferred from ActiveJob Queue Adapter.
You could also create your own to better fit your needs.

You can see how tracking strategies work in more detail [here](./docs/full.md#tracking-strategy)

Requirements
---

* Rails ( >= 4.0 )
* ActiveJob ( add `gem 'activejob_backport'` to Gemfile if 4.0 <= Rails < 4.2 )
* jQuery ( >= 1.5 )

Installation
---

Add to your application's Gemfile:

```ruby
gem 'immortus'
```

And then execute:

    $ bundle

Getting started
---

### Setup

```javascript
// Require Immortus in your Manifest ( make sure jQuery is included at this point ):

//= ...
//= require immortus
```

### Example 1: Track an ongoing Invoice job and notify the UI when finished

```javascript
$('.js-track-invoice').each(function() {
  Immortus.verify({ job_id: $(this).data('job-id') })
          .then(function(data) { console.log(data.job_id + ' finished successfully.'); });
});
```

```ruby
# config/routes.rb
Rails.application.routes.draw do
  # Add the route to default verify
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

### Example 2: Create an Invoice job and notify the UI when finished

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
  # Add the route to default verify and job creation
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

Full documentation
---

For a full documentation on how this works please check:

* [Routes](./docs/full.md#routes)
* [Controller](./docs/full.md#controller)
* [Tracking Strategies](./docs/full.md#tracking-strategy)
* [Immortus::Job](./docs/full.md#immortus-job)
* [Immortus JavaScript](./docs/full.md#immortus-javascript)

Some more advanced examples
---

`Immortus` can be used for more complex work by allowing [custom strategies](./docs/full.md#define-a-custom-tracking-strategy) and [custom verify controllers](./docs/full.md#how-to-create-a-custom-verify). Just a few examples:

* [Image Processor ( custom strategy )](./docs/examples/custom_strategy.md)
* [Background Video Processor ( custom verify )](./docs/examples/custom_verify.md)
* TODO: Add more examples here

Development
---

For test with guard

    $ bundle exec guard

Future Developments
---

* Support all ActiveJob adapters
* Support Web Sockets

For more details see the [ROADMAP](./docs/ROADMAP.md)

Contributing
---

1. Fork it ( https://github.com/runtime-revolution/immortus/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

License
---

Copyright © 2015 [Runtime Revolution](http://www.runtime-revolution.com), released under the MIT license.

About Runtime Revolution
---

![Runtime Revolution](http://webpublishing.s3.amazonaws.com/runtime_small_logo.png)

`Immortus` is maintained by [Runtime Revolution](http://www.runtime-revolution.com).
See our [other projects](https://github.com/runtimerevolution/) and check out our [blog](http://www.runtime-revolution.com/runtime/blog) for the latest updates.
