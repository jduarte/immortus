Tracking Strategies
===

Delayed::Job Strategy
---

Since Delayed::Job already persist data we don't need none of the callbacks, we just need to define status and find

### status

##### :finished

- Whenever a job is finished Delayed::Job will delete that record from the DB
- By default, when it reaches the maximum number of failed tries it also delete the record from DB (false positive)

##### :started

- If a job has started perform or has previous attempts (column locked_at has value or column attempts has a number greater than 0)

##### :created

- If none of above

### find

- Look for job_id inside handler column (NOT VERY EFFICIENT...)




Custom Strategy
---

Since Delayed::Job already persist data we don't need none of the callbacks, we just need to define status and find

### job_enqueued(job_id)

callback from ActiveJob called when job is enqueued ( usually used to persist job data )

### job_started(job_id)

callback from ActiveJob called when job is started

### job_finished(job_id)

callback from ActiveJob called when job is successfully finished

### rescue_from(exception, &block)

To use in case of error

```ruby
rescue_from ActiveRecord::RecordNotFound do
  strategy.do_something_because_an_exception_raised!
end
```

### status(job_id)

##### :finished

should be returned if job run with success

##### :started

should be returned if job already run at least once

##### :created

should be returned if job never run (in queue)

### find(job_id)

this is a private method.

should return a row or object with job info
