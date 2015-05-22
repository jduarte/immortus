JavaScript
===

Require Immortus JS
---

Require Immortus in your manifest file ( make sure jQuery is included at this point ):

```javascript
// in your main js file: usually assets/javascript/application.js

//= ...
//= require immortus
```

### To create and track an async job call in your JS:

```javascript
var jobCreatedSuccessfully = function(data) {
  // Executed when `create job` AJAX request returns with a 2xx status code
  console.log('Job ' + data.job_id + ' created successfully');

  // We must return here the `job_id` in order for the `verify` function receive this argument.
  return data.job_id;
}

var jobFailedToCreate = function() {
  // Executed when `create job` AJAX request returns with a non 2xx status code
  console.log('Job failed to create');
}

var jobFinished = function(data) {
  // Executed when a job is finished
  console.log('Job ' + data.job_id + 'finished successfully');
}

var jobFailed = function(data) {
  // Executed when a `verify job` AJAX requests returns with a non 2xx status code
  console.log('Job ' + data.job_id + ' failed to perform');
}

var jobInProgress = function(data) {
  // Executed every `verify job` AJAX request (each `longPolling` milliseconds, defaults to 1000)
  console.log('Job is still executing ...');
}

Immortus.create('/create_job')
        .then(jobCreatedSuccessfully, jobFailedToCreate)
        .then(function(job_id) {
          return Immortus.verify('/verify_job/' + job_id, { longPolling: { interval: 5000 } });
        })
        .then(jobFinished, jobFailed, jobInProgress);
```

### To only track an existing job without creating it:

```javascript
// You can also use only the `verify` callback to verify only without creating the job.
// In this case we need to pass the `job_id` directly because it will not be received from the `jobCreatedSuccessfully` callback
Immortus.verify({ job_id: '908ec6f1-e093-4943-b7a8-7c84eccfe417', jobClass: 'job_class' }, { longPolling: { interval: 5000 } })
        .then(jobFinished, jobFailed, jobInProgress);
});
```
