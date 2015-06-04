# CSV Processor

In this example:

* A User uploads a CSV to the server, by AJAX, to be processed
* The job will perform the CSV processing row by row and will update the percentage as it goes
* It will use an ActiveRecord model to store the job status
* The UI will show the percentage being updated

### Add to your Routes

```ruby
# config/routes.rb
Rails.application.routes.draw do
  get '/csvs', to: 'csv#index'
  # ...
  immortus_jobs do
    post 'process_csv', to: 'csv#process', as: 'process_csv'
  end
end
```

### Create a job

```ruby
# app/jobs/process_csv_job.rb
class CsvProcessorJob < ActiveJob::Base
  include Immortus::Job

  tracking_strategy :csv_processor_strategy

  def perform(file)
    reader = CsvReader.new(file)

    rows_processed = 0
    total = reader.total_rows
    reader.each_row do |row|
      Processor.new(row).do_some_stuff_with_this_row_data!
      rows_processed += 1
      percentage = ((rows_processed.to_f / total) * 100).floor
      strategy.update_progress(self.job_id, percentage)
    end
  end
end
```

### Generate job method

```ruby
class CsvController < ApplicationController

  # Allow us to check how CSVs being processed status are
  def index
    @csvs_being_processed = JobProgress.where('status != ?', 'finished')
  end

  # Respond to AJAX requests to create new Jobs
  def process
    job = CsvProcessorJob.perform_later(params[:csv][:file])
    render_immortus(job)
  end
end
```

### Model

```shell
$ bundle exec rails generate model JobProgress job_id: string status:string percentage:integer
$ bundle exec rake db:migrate
```

```ruby
# == Schema Information
#
# Table name: job_progresses
#
#  id                               :integer          not null, primary key
#  job_id                           :string(255)      not null
#  status                           :string(255)      not null
#  percentage                       :integer          not null
#
class JobProgress < ActiveRecord::Base
end
```

### Tracking Strategy

```ruby
# app/jobs/tracking_strategy/csv_processor_strategy.rb
module TrackingStrategy
  class CsvProcessorStrategy

    def job_enqueued(job_id)
      JobProgress.create!(job_id: job_id, status: 'enqueued', percentage: 0)
    end

    def job_started(job_id)
      job = find(job_id)
      job.update_attributes(status: 'running')
    end

    def job_finished(job_id)
      job = find(job_id)
      job.update_attributes(status: 'finished', percentage: 100)
    end

    def update_progress(job_id, percentage)
      job = find(job_id)
      job.update_attributes(percentage: percentage)
    end

    def completed?(job_id)
      job = find(job_id)
      job.status == 'finished'
    end

    # Hash returned in this method (it's a default verify feature) will be sent to verify JavaScript callbacks
    def meta(job_id)
      job = find(job_id)
      { percentage: job.percentage }
    end

    private

    def find(job_id)
      JobProgress.find_by(job_id: job_id)
    end
  end
end
```

### View

```erb
<!-- app/views/csv/index.html.erb -->

<%= form_for :csv, url: process_csv_path, html: { class: 'csv-uploader' } %>
  <%= f.file :file %>
  <%= f.submit 'Submit CSV' %>
<% end %>

<ul class="csv-processing-list">
  <% @csvs_being_processed.each do |csv| %>
    <li class="csv" data-job-id="<%= csv.job_id %>">
      CSV PROGRESS: <span class="progress-status"><%= csv.percentage %></span>%
    </li>
  <% end %>
</ul>
```

### JavaScript

```javascript
var csvJobCreated = function(data) {
  $('.csv-processing-list')
    .append('<li class="csv" data-job-id="' + data.job_id + '">CSV PROGRESS: <span class="progress-status">' + data.percentage + '</span>%</li>');

  return { job_id: data.job_id, job_class: data.job_class };
};

var csvProcessed = function(data) {
  // Processor finished. Remove from list
  $('.csv-processing-list [data-job-id=' + data.job_id + ']').remove();
};

var csvFailedToProcess = function(data) {
  $('.csv-processing-list [data-job-id=' + data.job_id + ']').addClass('error');
};

var csvOnProgress = function(data) {
  // Update progress in the UI
  $('.csv-processing-list [data-job-id=' + data.job_id + '] .progress-status')
    .html(data.percentage);
};

var verify_csv = function(job_id) {
  // We need to manually send the `job_class` to the server in each
  // `verify` GET request in order to `default verify` controller
  // know which strategy it should use
  return Immortus.verify({ job_id: job_id, job_class: 'CsvProcessorJob' })
                 .then(csvProcessed, csvFailedToProcess, csvOnProgress);
}

// On page load
$(function() {
  // Handle new CSVs updated by AJAX
  $('form.csv-uploader').on('submit', function(ev) {
    ev.preventDefault();

    Immortus.create('/process_csv')
            .then(csvJobCreated)
            .then(function(jobInfo) {
              return verify_csv(jobInfo.job_id);
            });
  });

  // Perform `verify` on existing CSVs that haven't finished processing
  $.each( $('.csv-processing-list .csv'), function(i, v) {
    var job_id = $(this).data('job-id');
    verify_csv(job_id);
  });
});
```
