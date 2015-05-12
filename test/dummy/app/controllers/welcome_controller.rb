class WelcomeController < ApplicationController
  def index
  end

  def wait
    job = WaitABitJob.perform_later
    render_immortus job
  end
end
