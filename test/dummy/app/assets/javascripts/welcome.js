$(function() {
  $('.js-queue-action').click(function(e) {
    e.preventDefault();

    Immortus.perform({
      url: $(this).attr('href'),
      longpolling: {
        interval: 1000
      },
      beforeSend: function() { console.log('before create'); },
      afterEnqueue: function(job_id, enqueue_successfull) { console.log('after create, ' + job_id + ', ' + enqueue_successfull); },
      completed: function(successfull) { console.log('completed, ' + successfull); }
    });

  });
});
