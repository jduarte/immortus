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

optional method.

callback from ActiveJob called when job is enqueued ( usually used to persist job data )

### job_started(job_id)

optional method.

callback from ActiveJob called when job is started

### job_finished(job_id)

optional method.

callback from ActiveJob called when job is successfully finished

### completed?(job_id)

mandatory method if using default verify controller.

should return a boolean ( true if job is finished, false otherwise )

### meta(job_id)

optional method.

returned hash will be added in every verify request

### find(job_id)

this is a private method.

should return a row or object with job info
