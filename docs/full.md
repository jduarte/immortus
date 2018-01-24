Documentation
===

Routes
---

`Immortus` has a DSL route (`immortus_jobs`) so you can use __default verify__ and to help make your jobs code in same place.

```ruby
# config/routes.rb
Rails.application.routes.draw do
  immortus_jobs do
    post 'create_a_job', to: 'job_creation#job'
    post 'create_other_job', to: 'job_creation#other_job'
  end

  # This is the same as doing:
  get '/immortus/verify/:job_id(/:job_class)', to: 'immortus#verify', as: :verify_immortus_job
  post 'create_a_job', to: 'job_creation#job'
  post 'create_other_job', to: 'job_creation#other_job'
end
```

The use of `immortus_jobs` is not mandatory but is recommended to be sure we can use __default verify__, it should only be used once.

Controller
---

### Create Job

`Immortus` has a render (`render_immortus(job)`) that help you send needed data to `Immortus.create` JavaScript callback

```ruby
# app/controllers/sample_controller.rb
class SampleController < ApplicationController
  def generate_job
    job = MyJob.perform_later
    render_immortus(job)
  end
end
```

To this to work you need to use ActiveJob `perform_later` method, otherwise it will not generate a job_id.

`render_immortus` sends `job_id` and `job_class` to `Immortus.create` JavaScript callbacks.
`render_immortus(job)` is the same as write:

```ruby
if job.try('job_id')
  render json: { job_id: job.job_id, job_class: job.class.name }
else
  render json: {}, status: 500
end
```

### Verify

Verify is called from JavaScript to check a specific job status, so it is responsible to send info about one job.

##### How does default verify works

__default verify__ is a simple verify method `Immortus` bring to you for convenience.

It send `completed` to JavaScript if verify successfully run, i.e. strategy returns without error.
It always send `job_id` to JavaScript even if it fails to verify the job.

It also works with job [Inline Tracking Strategy](#inline-tracking-strategy) override if you also send `job_class` in `Immortus.verify` JavaScript call.

It has the ability to send extra fields to JS, you just need to define the method `meta(job_id)` in your strategy and return a hash with the extra fields you want.
If you want to add the field progress you could do something like:

```ruby
# app/jobs/tracking_strategy/some_custom_strategy.rb
module TrackingStrategy
  class SomeCustomStrategy
    # ...

    def meta(job_id)
      job = SomeTable.find_by(job_id: job_id)

      {
        progress: job.progress
      }
    end

  end
end
```

you could also create your own custom verify

##### How to create a custom verify

you will need to add a `get` route, something like this:

```ruby
# config/routes.rb
Rails.application.routes.draw do
  # ...

  immortus_jobs do
    # ...

    get  "job_custom_verify/:job_id", :to => "job_custom_verify#verify"
  end
end
```

and create the controller method returning a JSON used in JavaScript (`data` argument).
`completed` must be one of the returned keys, so JavaScript knows when to stop `Polling`
so it should be true if job is finished.

```ruby
# app/controllers/job_custom_verify_controller.rb
class JobCustomVerifyController < ApplicationController
  def verify
    strategy = JobCustomVerify.strategy

    render json: {
      :completed => strategy.completed?(params[:job_id]),
      :percentage => strategy.percentage(params[:job_id])
    }
  end
end
```

Tracking Strategy
---

### How configure which strategy should a job use?

Tracking strategies are Ruby Objects that `Immortus` uses to track Jobs statuses. It will use an available tracking strategy in the following order:

1. If the Job has defined an [Inline Tracking Strategy](#inline-tracking-strategy) it will use it.
2. If not it will use the [User Global Configured](#user-global-configured) if defined
3. Otherwise it will be [Inferred from the ActiveJob Queue Adapter](#inferred-from-the-activejob-queue-adapter)

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

| ActiveJob QueueAdapter |    Inferred Strategy    |                      Wiki                      |
|-----------------------:|:-----------------------:|:----------------------------------------------:|
|           :delayed_job | :delayed\_job\_strategy | [How it works?](#delayed-job-strategy)         |
|            :backburner |           N/A           |                       N/A                      |
|                    :qu |           N/A           |                       N/A                      |
|                   :que |           N/A           |                       N/A                      |
|         :queue_classic |           N/A           |                       N/A                      |
|               :sidekiq |    :sidekiq\_strategy   | [How it works?](#sidekiq-strategy)             |
|              :sneakers |           N/A           |                       N/A                      |
|          :sucker_punch |           N/A           |                       N/A                      |
|                :inline |           N/A           |                       N/A                      |


### Define a custom tracking strategy

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

### How inferred Strategies works

#### Delayed::Job Strategy

Since Delayed::Job already persist data we don't need none of the callbacks, we just need to define completed? and find

##### completed?(job_id)

- Whenever a job is finished Delayed::Job will delete that record from the DB
- By default, when it reaches the maximum number of failed tries it also delete the record from DB (false positive?)

##### find(job_id)

- Look for job_id inside handler column (NOT VERY EFFICIENT...)

Immortus::Job
---

To give any ActiveJob the power of strategies just include `Immortus::Job`

```ruby
# app/jobs/my_job.rb
class MyJob < ActiveJob::Base
  include Immortus::Job

  def perform(*args)
    # ...
  end
end
```

this way you could keep track of your job.

To override the strategy used in some job you can use tracking_strategy method

```ruby
# app/jobs/my_job.rb
class MyJob < ActiveJob::Base
  include Immortus::Job

  tracking_strategy :custom_tracking_strategy_to_my_job

  def perform(*args)
    # ...
  end
end
```

You can use all the functionality ActiveJob gives to you, like:

```ruby
class ProcessVideoJob < ActiveJob::Base
  include Immortus::Job

  queue_as do
    video = self.arguments.first
    if video.owner.premium?
      :premium_videojobs
    else
      :videojobs
    end
  end

  rescue_from(ActiveRecord::RecordNotFound) do |exception|
    # Do something with the exception
  end

  def perform(video)
    # Do process video
  end
end
```

Immortus JavaScript
---

For all JavaScript code snippets we are using this functions to illustrate what is going on

```javascript
var jobCreatedSuccessfully = function(data) {
  // Executed when `create job` AJAX request returns with a 2xx status code
  console.log('Job ' + data.job_id + ' created successfully');

  // We must return here the `job_id` or `verify_job_url` in order for the `verify` function receive this argument.
  // We also must return the `job_class` if using more then 1 strategy in application and `verify_job_url` is not sent.
  // ex.:
  // return { job_id: data.job_id, job_class: data.job_class }
  // or
  // return { verify_job_url: '/my_custom_verify_route/' + data.job_id }
  // since data by default has all we need we are returning it
  return data;
}

var jobFailedToCreate = function() {
  // Executed when `create job` AJAX request returns with a non 2xx status code
  console.log('Job failed to create');
}

var jobFinished = function(data) {
  // Executed when a job is finished
  console.log('Job ' + data.job_id + ' finished successfully');
}

var jobFailed = function(data) {
  // Executed when a `verify job` AJAX requests returns with a non 2xx status code
  // Depending on how controller code it's done, and type of error, data could be empty.
  // Ex.:
  // if we set to a wrong verify route (i.e. with a typo, not in routes, etc) we will receive an empty data.
  console.log('Job ' + data.job_id + ' failed to perform');
}

var jobInProgress = function(data) {
  // Executed every `verify job` AJAX request
  // it is called each `polling.interval` milliseconds (defaults to 500) after last success,
  // until completed or failed
  console.log('Job ' + data.job_id + ' is still executing ...');
}
```

### To create and track an async job call in your JS:

```javascript
Immortus.create('/create_job')
        .then(jobCreatedSuccessfully, jobFailedToCreate)
        .then(function(jobInfo) {
          return Immortus.verify(jobInfo, { polling: { interval: 800 } })
                         .then(jobFinished, jobFailed, jobInProgress);
        });

// this will produce:
//  if fail to create:
//    Job failed to create
//  if success creation but fail verify
//    job a55b6de4-7b06-4b80-b414-8085097488db created successfully
//    job a55b6de4-7b06-4b80-b414-8085097488db failed to perform
//  if success creation and verify
//    job a55b6de4-7b06-4b80-b414-8085097488db created successfully
//    job a55b6de4-7b06-4b80-b414-8085097488db is still executing ...
//    job a55b6de4-7b06-4b80-b414-8085097488db is still executing ...
//    job a55b6de4-7b06-4b80-b414-8085097488db is still executing ...
//    this previous lines can be repeated more/less times, depending on what the job is doing and `interval`
//    job a55b6de4-7b06-4b80-b414-8085097488db finished successfully
```

### To only track an existing job without creating it:

```javascript
// You can also use only the `verify` callback to verify only without creating the job.
// In this case we need to pass the `job_id` directly because
// it will not be received from the `jobCreatedSuccessfully` callback

var jobInfo = {
  // jobId is recommended to be set
  job_id: '908ec6f1-e093-4943-b7a8-7c84eccfe417',
  // JobClass is needed if more than 1 strategy is used, otherwise can be ignored
  job_class: 'job_class',
  // if we want to use a custom verify route & controller we could set verify_job_url
  // this will override default controller so `jobClass` will be ignored
  // (unless you use it in your custom controller),
  // i.e. if verify_job_url is defined it will ignore `jobId` and `jobClass`
  verify_job_url: '/custom_verify_path/with_job_id'
};

var options = {
  // currently we only support polling
  polling: {
    // `interval` is the minimum wait time in millisconds from last success request (default is 500)
    // i.e. if server responds in 200ms and we set `interval` to 800
    //      we get a new request in server every second (aprox.)
    interval: 800
  }
};

Immortus.verify(jobInfo, options)
        .then(jobFinished, jobFailed, jobInProgress);

// this will produce:
//  if fail verify
//    job 908ec6f1-e093-4943-b7a8-7c84eccfe417 failed to perform
//  if success verify
//    job 908ec6f1-e093-4943-b7a8-7c84eccfe417 is still executing ...
//    job 908ec6f1-e093-4943-b7a8-7c84eccfe417 is still executing ...
//    job 908ec6f1-e093-4943-b7a8-7c84eccfe417 is still executing ...
//    this previous lines can be repeated more/less times, depending on what the job is doing and `interval`
//    job 908ec6f1-e093-4943-b7a8-7c84eccfe417 finished successfully
```
