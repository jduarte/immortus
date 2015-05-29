Tracking Strategies
===

Tracking strategies are Ruby Objects that Immortus uses to track Job's status. It will use an available tracking strategy in the following order:

## How configure which strategy should a job use?

1. If the Job has defined an [Inline Tracking Strategy](./docs/tracking_strategies.md) it will use it.
2. If not it will use the [User Global Configured](./docs/tracking_strategies.md) if defined
3. Otherwise it will be [Inferred from the ActiveJob Queue Adapter](./docs/tracking_strategies.md)

#### Inline Tracking Strategy

```ruby
# app/jobs/generate_invoice_job.rb
class GenerateInvoiceJob < ActiveJob::Base
  include Immortus::Job

  # This will set this `redus_pub_sub_strategy` for this job only
  tracking_strategy :redis_pub_sub_strategy

  # ...
end
```

#### User Global Configured

Define in your Rails project an initializer that will set the tracking strategy to be used for all jobs.

```ruby
# config/initializer/immortus.rb

Immortus::Job.tracking_strategy = :redis_pub_sub_strategy

# you could also specify the class directly:
Immortus::Job.tracking_strategy = TrackingStrategy::RedisPubSubStrategy
```

#### Inferred from the ActiveJob Queue Adapter

The tracking strategy will be inferred from the Rails ActiveJob adapter ( config.active_job.adapter )

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


## Define a custom tracking strategy

You can define a custom strategy to control how should your job be tracked:

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

    # if `meta` method is defined, the returned hash this will be added in every verify request
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
```

Here is a list of what methods you can use when making a custom tracking strategy:

|    Method    | Mandatory |   Type   |                                      Description                                     |
|:------------:|:---------:|:--------:|:------------------------------------------------------------------------------------:|
|  completed?  |  Required |          |           Should return a boolean. True if job completed, false otherwise.           |
|     meta     |  Optional |          | Additonal data that will be appended to the JSON response. Should return a ruby Hash |
| job_enqueued |  Optional | Callback |          Called when job was enqueued by ActiveJob 'after_enqueue' callback          |
|  job_started |  Optional | Callback |          Called when job was started by ActiveJob 'before_perform' callback          |
| job_finished |  Optional | Callback |          Called when job was finished by ActiveJob 'after_perform' callback          |


----

TODO: Move this out of this .MD

How it works
---

Delayed::Job Strategy
---

Since Delayed::Job already persist data we don't need none of the callbacks, we just need to define completed? and find

### completed?(job_id)

- Whenever a job is finished Delayed::Job will delete that record from the DB
- By default, when it reaches the maximum number of failed tries it also delete the record from DB (false positive?)

### find(job_id)

- Look for job_id inside handler column (NOT VERY EFFICIENT...)


