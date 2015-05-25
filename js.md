JavaScript
===

Require Immortus JS
---

Require Immortus in your manifest file ( make sure jQuery is included at this point ):

```javascript
//= ...
//= require immortus
```

For next examples we are using this simple functions to illustrate what is going on

```javascript
var jobCreatedSuccessfully = function(data) {
  // Executed when `create job` AJAX request returns with a 2xx status code
  console.log('Job ' + data.job_id + ' created successfully');

  // We must return here the `job_id` in order for the `verify` function receive this argument.
  return { jobId: data.job_id, jobClass: data.job_class };
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
  console.log('Job ' + data.job_id + ' failed to perform');
}

var jobInProgress = function(data) {
  // Executed every `verify job` AJAX request (each `longPolling` milliseconds, defaults to 1000)
  console.log('Job ' + data.job_id + ' is still executing ...');
}
```

### To create and track an async job call in your JS:

```javascript
Immortus.create('/create_job')
        .then(jobCreatedSuccessfully, jobFailedToCreate)
        .done(function(jobObject) {
          return Immortus.verify(jobObject, { longPolling: { interval: 800 } })
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

var jobObject = {
  // jobId is recommended to be set
  jobId: '908ec6f1-e093-4943-b7a8-7c84eccfe417',
  // JobClass is needed if more than 1 strategy is used, otherwise can be ignored
  jobClass: 'job_class',
  // if we want to use a custom verify route & controller we could verifyJobUrl
  // this will override default controller so `jobClass` will be ignored
  // (unless you use it in your custom controller),
  // i.e. if verifyJobUrl is defined it will ignore jobId and jobClass
  verifyJobUrl: '/custom_verify_path/with_job_id'
};

var options = {
  // currently we only support longPolling
  longPolling: {
    // `interval` is the minimum wait time in millisconds from last success request (default is 500)
    // i.e. if server responds in 200ms and we set `interval` to 800
    //      we get a new request in server every second (aprox.)
    interval: 800
  }
};

Immortus.verify(jobObject, options)
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
