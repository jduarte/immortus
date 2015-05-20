Immortus Default Tracking Strategies
===

Delayed::Job Strategy
---

Since Delayed::Job already persist data we don't need none of the callbacks, we just need to define status and find

### status

#### :finished

- Whenever a job is finished Delayed::Job will delete that record from the DB
- By default, when it reaches the maximum number of failed tries it also delete the record from DB (false positive)

#### :started

- If a job has started perform or has previous attempts (column locked_at has value or column attempts has a number greater than 0)

#### :created

- If none of above

### find

- Look for job_id inside handler column (NOT VERY EFFICIENT...)
