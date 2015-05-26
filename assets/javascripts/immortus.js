var Immortus = (function() {
  var api = {};

  api.create = function(url) {
    return $.post(url, null, null, 'json');
  };

  api.verify = function(jobOptions, options) {
    var defer = $.Deferred();
    var url = jobOptions.verifyJobUrl;
    var timeout = (options.longPolling && options.longPolling.interval) || 500

    if(!url) {
      url = '/immortus/verify/' + jobOptions.job_id;

      if (jobOptions.job_class) {
        url = url + '/' + jobOptions.job_class;
      }
    }

    var verifyCall = function() {
      $.get(url, null, successFn, 'json').fail(failFn);
    }

    var successFn = function(data, textStatus, jqXHR) {
      if(data.completed) {
        defer.resolve(data);
      } else {
        defer.notify(data);
        setTimeout(function() { verifyCall() }, timeout);
      }
    };

    var failFn = function(jqXHR, textStatus, errorThrown) {
      defer.reject(jqXHR.responseJSON || {})
    }

    verifyCall();

    return defer.promise();
  };

  return api;
})();
