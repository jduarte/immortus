Tracking Strategies
===

How it works
---

Each job has a strategy that is responsible to track it.

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

Delayed::Job Strategy
---

Since Delayed::Job already persist data we don't need none of the callbacks, we just need to define completed? and find

### completed?(job_id)

- Whenever a job is finished Delayed::Job will delete that record from the DB
- By default, when it reaches the maximum number of failed tries it also delete the record from DB (false positive?)

### find(job_id)

- Look for job_id inside handler column (NOT VERY EFFICIENT...)




Custom Strategy
---

There are two ways to use a custom strategy:

- with the default verify controller
    - completed?(job_id) is mandatory
    - meta(job_id) is used to send extra data to JS
- with custom verify controller
    - no mandatory methods
    - custom controller method specifies what should be sent to JS

### default verify controller methods

##### completed?(job_id)

This is a mandatory method if using default verify controller.

should return a boolean ( true if job is finished, false otherwise )

##### meta(job_id)

This is a optional method.

returned hash will be added in every verify request

### callbacks

##### job_enqueued(job_id)

This is a optional method, recommended to use in custom strategies to persist job data.

callback from ActiveJob called when job is enqueued

##### job_started(job_id)

This is a optional method.

callback from ActiveJob called when job is started (is out of the queue, being processed)

##### job_finished(job_id)

This is a optional method, recommended to use in custom strategies to mark job as finished.

callback from ActiveJob called when job is successfully finished
