Minimalistic Immortus Details
===

We assume you already have jobs created and just need to know when they finish and just want to change the minimum possible

Routes (file: config/routes.rb)
---

```ruby
Rails.application.routes.draw do
  # ...

  immortus_jobs

  # same as write:
  # get '/immortus/verify/:job_id(/:job_class)', to: 'immortus#verify'
end
```

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

JS
---

Require Immortus in your manifest file ( make sure jQuery is included at this point ):

```javascript
//= ...
//= require immortus
```

JS Verify
---

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
