var Immortus = (function () {
  var api = {};

  api.create = function (url, data) {
    if (!data) { data = {}; }
    data.authenticity_token = $('[name="csrf-token"]')[0].content;
    return $.post(url, data, null, 'json');
  };

  api.verify = function (jobOptions, options) {
    var defer = $.Deferred();
    var timeout = (options && options.polling && options.polling.interval) || 500;
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
      if (jqXHR.status === 0) {
        if (window.console && window.console.log) {
          console.log('empty response');
        }

        return false;
      }

      defer.reject(jqXHR.responseJSON || {});
    };

    verifyCall();

    return defer.promise();
  };

  return api;
}());
