module ActionDispatch
  module Routing
    class Mapper
      def immortus_jobs(*args, &block)
        get '/immortus/verify/:job_id(/:job_class)', to: 'immortus#verify', as: :verify_immortus_job
        yield if block_given?
      end
    end
  end
end
