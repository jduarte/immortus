# CSV Processor

In this example:

* A User uploads a CSV to the server to be processed
* The job will perform the CSV processing row by row and will update the percentage as it goes
* The UI will show the percentage being updated

### Routes

```ruby
# config/routes.rb
Rails.application.routes.draw do
  immortus_jobs do
    post 'process_csv', to: 'csv#process'
  end
end
```

### Generate job method

```ruby
class CsvController < ApplicationController
  def process
    job = CsvProcessorJob.perform_later(params[:file])
    render_immortus(job)
  end
end
```

### Job

```ruby
# app/jobs/process_csv_job.rb
class CsvProcessorJob < ActiveJob::Base
  include Immortus::Job

  tracking_strategy :csv_processor_strategy

  def perform(file)
    reader = CsvReader.new(file)

    rows_processed = 0
    reader.each_row do |row|
      Processor.new(row).do_some_stuff_with_this_row_data!
      rows_processed += 1
      percentage = ((rows_processed.to_f / reader.total_rows) * 100).floor
      strategy.update_progress(self.job_id, percentage)
    end
  end
end
```

### Tracking Strategy

```ruby
# app/jobs/tracking_strategy/csv_processor_strategy.rb
module TrackingStrategy
  class CsvProcessorStrategy

    def job_enqueued(job_id)
      CsvProcessorTable.create!(job_id: job_id, status: 'enqueued', percentage: 0)
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

      result = { percentage: job.percentage }

      result[thumbnail] = job.thumbnail unless job.thumbnail.blank?

      result
    end

    private

    def find(job_id)
      CsvProcessorTable.find_by(job_id: job_id)
    end
  end
end
```

### HTML

```erb
<div class="csvs">
  <% @csvs_being_processed.each do |csv| %>
    <div class="csv" data-job-id="<%= csv.job_id %>">

    </div>
  <% end %>
</div>
```

### JavaScript Create

```javascript
var csvCreated = function(data) {
  $('.csvs').append('<div class="csv-' + data.job_id + '"><span class="loading-icon"></span></div>');

  return { job_id: data.job_id, job_class: data.job_class };
};

var csvProcessed = function(data) {
  $('.csvs > .csv-' + data.job_id).html('<img src="' + data.thumbnail + '">');
};

var csvNotProcessed = function(data) {
  alert('csv could not be processed');
};

var processingcsv = function(data) {
  $('.csvs > .csv-' + data.job_id).html('<span>progress: ' + data.percentage + '</span>');
};

Immortus.create('/process_csv')
        .then(csvCreated)
        .then(function(jobInfo) {
          return Immortus.verify(jobInfo)
                         .then(csvProcessed, csvNotProcessed, processingcsv);
        });
```

### JavaScript Verify

We need this if we want the info to persist in a refresh

```html
<div class="csvs">
  <!-- ... -->
  <div class="csv-908ec6f1-e093-4943-b7a8-7c84eccfe417"><span class="loading-icon"></span></div>
</div>
```

```javascript
// using some of the same functions from `JavaScript Create` section

// In this case we need to explicitly set `job_class` to be sure we use the correct strategy
var jobInfo = {
  job_id: '908ec6f1-e093-4943-b7a8-7c84eccfe417',
  job_class: 'CsvProcessorJob'
};

Immortus.verify(jobInfo)
        .then(csvProcessed, csvNotProcessed, processingcsv);
```
