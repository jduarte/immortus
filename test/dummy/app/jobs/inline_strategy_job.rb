class InlineStrategyJob < ActiveJob::Base
  include Immortus::Job

  queue_as :default

  tracking_strategy :custom_app_strategy

  def perform(*args)
  end
end
