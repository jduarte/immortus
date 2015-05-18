var Immortus = (function() {
  var api = {};

  function Immortus(options) {
    // TODO: Sanitize and normalize options
    this.options = options;

    this.interval = undefined;
    this.interval_milliseconds = options.longpolling.interval;
    this.url = options.url;
    this.job_id = options.job_id;
    this.setup = options.setup || function() { };
    this.beforeSend = options.beforeSend || function() { };
    this.afterEnqueue = options.afterEnqueue || function() { };
    this.completed = options.completed || function() { };
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
              that.completed(that.job_id, data.success);
            } else {
              that.completed(that.job_id, false);
            }
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
