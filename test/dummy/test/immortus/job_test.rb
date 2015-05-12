require 'test_helper'

# class JobTest < Immortus::Job
#   queue_as :default

#   def perform(*args)
#     # do stuff
#   end
# end

module Immortus
  class JobTest < ActiveSupport::TestCase
    def test_known_active_job_strategy
      # ::Rails.application.config.active_job.stub :queue_adapter { :delayed_job }
      assert_equal Immortus::TrackingStrategy::DelayedJobStrategy, Immortus::Job.strategy.class
    end

    def test_unknown_active_job_strategy
      ::Rails.application.config.active_job.stub :queue_adapter , :unknown do
        assert_equal '?', Immortus::Job.strategy.class
      end
    end

    def test_override_strategy
      ::Rails.application.config.immortus.expect(:tracking_strategy, :delayed_job)
      assert_equal Immortus::TrackingStrategy::DelayedJobStrategy, Immortus::Job.strategy.class
    end

    def test_override_unknown_strategy
      ::Rails.application.config.immortus.expect(:tracking_strategy, :unknown)
      assert_equal '?', Immortus::Job.strategy.class
    end
  end
end
