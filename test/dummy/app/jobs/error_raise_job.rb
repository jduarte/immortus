class ErrorRaiseJob < Immortus::Job

  def perform(*args)
    raise StandardError.new('Error raised during job execution')
  end

end
