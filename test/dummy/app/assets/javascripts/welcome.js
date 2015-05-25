$(function() {
  $('.js-queue-action').click(function(e) {
    e.preventDefault();

    var jobCreatedSuccessfully = function(data) {
      console.log('job ' + data.job_id + ' created');

      return { jobId: data.job_id, jobClass: data.job_class };
    }

    var jobFailedToCreate = function() {
      console.log('Job failed to create');
    }

    var jobInProgress = function(data) {
      console.log('job ' + data.job_id + ' running')
    }

    var jobFinished = function(data) {
      console.log('job ' + data.job_id + ' completed')
    }

    var jobFailed = function(data) {
      console.log('job ' + data.job_id + ' failed')
    }

    Immortus.create($(this).attr('href'))
      .then(jobCreatedSuccessfully, jobFailedToCreate)
      .done(function(jobObject) {
        return Immortus.verify(jobObject, { longPolling: { interval: 500 } })
                       .then(jobFinished, jobFailed, jobInProgress);
      });
  });
});
