Immortus::Job
===

ActiveJob
---

You can use ActiveJob features

### rescue_from(exception, &block)

To use in case of error

```ruby
rescue_from ActiveRecord::RecordNotFound do
  # do something because an exception raised!
end
```
