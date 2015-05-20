var Immortus = (function() {
  var api = {};

  function Immortus(options) {
    // TODO: Sanitize and normalize options
    this.options = options;

    this.interval = undefined;
    this.interval_milliseconds = options.longpolling.interval;
    this.url = options.url;
    this.job_id = options.job_id;

    // to be used in Immortus.perform
    this.beforeSend = options.beforeSend || function() { };
    this.afterEnqueue = options.afterEnqueue || function() { };

    // to be used in Immortus.verify
    this.setup = options.setup || function() { };

    // to be used in both Immortus.perform and Immortus.verify
    this.completed = options.completed || function() { };
    this.error = options.error || function() { };
  }

  Immortus.prototype.init = function() {
    var that = this;

    this.beforeSend();
    $.ajax({
      url: this.url,
      dataType: 'json'
    }).always(
      function(data, textStatus, jqXHR) {
        that.job_id = data.job_id;
        var success = textStatus === 'success';
        that.afterEnqueue(data.job_id, success);
        if (success) {
          that.startMonitor();
        }
      }
    );
  };

  Immortus.prototype.startMonitor = function() {
    var that = this;

    this.interval = setInterval(function() {
      $.ajax({
        url: '/immortus/verify/' + that.job_id,
        dataType: 'json'
      }).always(
        function(data, textStatus, jqXHR) {
          var req_success = textStatus === 'success';
          if(!req_success || data.completed) {
            clearInterval(that.interval);
            if (req_success) {
              that.completed(that.job_id, data.status, data.meta);
            } else {
              that.error(that.job_id, data.status, data.meta);
            }
          } else {
            // TODO: what should be done? change state callback? nothing?
          }
        }
      );
    }, this.interval_milliseconds || 1000);
  };

  api.perform = function(options) {
    var job = new Immortus(options);
    job.init();
  };

  api.verify = function(options) {
    var job = new Immortus(options);
    job.setup();
    job.startMonitor();
  };

  return api;
})();
