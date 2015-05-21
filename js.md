JavaScript
===

Requirements
---

```javascript
// in your main js file: usually assets/javascript/application.js

//= ...
//= require immortus
```

### To create and track an async job call in your JS:

```javascript
var logBeforeSend = function() {
  console.log('executed before AJAX request');
}

var logAfterEnqueue = function(data, enqueue_successfull) {
  console.log('job ' + data.job_id + ' was enqueued with ' + (enqueue_successfull ? 'success' : 'error'));
}

var logCompleted = function(data) {
  console.log('job ' + data.job_id + ' was finished with success');
}

var logError = function(data) {
  console.log('error in job ' + data.job_id);
}

Immortus.perform({
  createJobUrl: '/generate_invoice',
  longpolling: {
    interval: 2000,               // Defaults to 1000
  },
  beforeSend: logBeforeSend,      // Executed before the `create job` AJAX request. Defaults to empty function
  afterEnqueue: logAfterEnqueue,  // Executed after the `create job` AJAX request. Defaults to empty function
  completed: logCompleted,        // Executed when a `verify job` AJAX requests returns with a 2xx status code and job is finished. Defaults to empty function
  error: logError                 // Executed when a `verify job` AJAX requests returns with a non 2xx status code. Defaults to empty function
});
```

### To only track an existing job without creating it:

```javascript
Immortus.verify({
  job_id: '908ec6f1-e093-4943-b7a8-7c84eccfe417',
  longpolling: {
    interval: 2000,               // Defaults to 1000
  },
  beforeSend: logBeforeSend,           // Executed before the first `verify job` AJAX request. Defaults to empty function
  completed: logCompleted,        // Executed when a `verify job` AJAX requests returns with a 2xx status code and job is finished. Defaults to empty function
  error: logError                 // Executed when a `verify job` AJAX requests returns with a non 2xx status code. Defaults to empty function
});
```
