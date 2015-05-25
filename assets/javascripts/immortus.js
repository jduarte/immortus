var Immortus = (function() {
  var api = {};

  api.create = function(url) {
    return $.post(url, null, null, 'json');
  };

  api.verify = function(jobOptions, options) {
    var defer = $.Deferred();
    var url = jobOptions.verifyJobUrl;
    var default_return = { job_id: jobOptions.jobId };
    var timeout = (options.longPolling && options.longPolling.interval) || 500

    if(!url) {
      url = '/immortus/verify/' + jobOptions.jobId;

      if (jobOptions.jobClass) {
        url = url + '/' + jobOptions.jobClass;
      }
    }

    var verifyCall = function() {
      $.get(url, null, successFn, 'json').fail(failFn);
    }

    var successFn = function(data) {
      if(data.completed) {
        defer.resolve($.extend({}, default_return, data));
      } else {
        defer.notify($.extend({}, default_return, data));
        setTimeout(function() { verifyCall() }, timeout);
      }
    };

    var failFn = function() {
      defer.reject(default_return)
    }

    verifyCall();

    return defer.promise();
  };

  return api;
})();
