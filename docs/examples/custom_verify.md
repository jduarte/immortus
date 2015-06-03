# Background Video Processor

In this example:

* A User uploads a video to the server to be processed
* The UI will show the User medal if it has any
    * **Bronze** - Uploaded more than 5 videos
    * **Silver** - Uploaded more than 20 videos
    * **Gold** - Uploaded more than 50 videos

### Routes

```ruby
# config/routes.rb
Rails.application.routes.draw do
  immortus_jobs do
    # We will require a custom verify because we're gonna need to send
    # current_user related info and we don't have that info on the strategy
    get 'video_processor_verify/:job_id', to: 'video_processor#verify'
    post '/video_processor/create', :to => 'video_processor#create'
  end
end
```

### Job

```ruby
# app/jobs/video_processor_job.rb
class VideoProcessorJob < ActiveJob::Base
  include Immortus::Job

  def perform(user_id, video_raw_data)
    VideoProcessor.new(user_id, video_raw_data).save_and_extract_metadata!
  end
end
```

### Controller

```ruby
# app/controllers/job_custom_verify_controller.rb
class JobCustomVerifyController < ApplicationController

  def create
    VideoProcessorJob.perform_later(current_user.id, params[:video_raw_data])
  end

  # Custom verify
  def verify
    data = { :completed => VideoProcessorJob.strategy.completed?(params[:job_id]) }

    if data[:completed]
      data[:videos_processed_count] = current_user.videos_processed.count
    end

    # returned JSON will become available in every verify JavaScript callbacks
    render json: data
  end
end
```

##### NOTES

* Returned `json` will be available in `data` within JavaScript callbacks
* `completed` field is **required** and must be a Boolean

### HTML

```html
<div class="user-medals">
  <div class="medal medal-bronze" style="display: none;"></div>
  <div class="medal medal-silver" style="display: none;"></div>
  <div class="medal medal-gold"   style="display: none;"></div>
</div>
```

### JavaScript

```javascript
var jobCreated = function(data) {
  $('body').append('<h1 data-job-id=[' + data.job_id + ']>Video is processing ...</h1>');
};

var showMedal = function(data) {
  $('.medal').hide();
  if ( data.videos_processed_count > 50 ) {
    $('.medal-gold').show();
  } else if ( data.videos_processed_count > 20 ) {
    $('.medal-silver').show();
  } else if ( data.videos_processed_count > 5 ) {
    $('.medal-bronze').show();
  }
};

Immortus.create('/video_processor/create')
        .then(jobCreated)
        .then(function(jobInfo) {
          var verifyJobUrl = '/video_processor_verify/' + jobInfo.job_id;
          return Immortus.verify({ verify_job_url: verifyJobUrl })
                         .then(showMedal);
        });
```
