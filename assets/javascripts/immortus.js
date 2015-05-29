var Immortus = (function () {
  var api = {};

  api.create = function (url) {
    return $.post(url, null, null, 'json');
  };

  api.verify = function (jobOptions, options) {
    var defer = $.Deferred();
    var timeout = (options && options.longPolling && options.longPolling.interval) || 500;
    var url = jobOptions.verify_job_url;
    var verifyCall, successFn, failFn;

    if (!url) {
      url = '/immortus/verify/' + jobOptions.job_id;

      if (jobOptions.job_class) {
        url = url + '/' + jobOptions.job_class;
      }
    }

    verifyCall = function () {
      $.get(url, null, successFn, 'json').fail(failFn);
    };

    //function(data, textStatus, jqXHR)
    successFn = function (data) {
      if (data.completed) {
        defer.resolve(data);
      } else {
        defer.notify(data);
        setTimeout(verifyCall, timeout);
      }
    };

    // function(jqXHR, textStatus, errorThrown)
    failFn = function (jqXHR) {
      defer.reject(jqXHR.responseJSON || {});
    };

    verifyCall();

    return defer.promise();
  };

  return api;
}());
