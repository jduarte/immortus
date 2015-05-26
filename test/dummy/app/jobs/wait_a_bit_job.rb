class WaitABitJob < ActiveJob::Base
  include Immortus::Job

  queue_as :default

  def perform(*args)
  end
end
