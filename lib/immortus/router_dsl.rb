module ActionDispatch
  module Routing
    class Mapper
      def immortus_jobs(*args, &block)
        get '/immortus/verify/:job_id', to: 'immortus#verify', as: :verify_immortus_job
        yield
      end
    end
  end
end
