class WaitABitJob < Immortus::Job
  queue_as :default

  def perform(*args)
  end
end
