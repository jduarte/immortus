require 'immortus/engine' if defined?(::Rails)
require 'immortus/renders'
require 'immortus/router_dsl'
require 'immortus/job'
require 'immortus/strategy_finder'
require 'immortus/tracking_strategy/delayed_job_active_record_strategy'

module Immortus
end
