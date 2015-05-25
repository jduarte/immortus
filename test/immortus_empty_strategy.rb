module Immortus
  module TrackingStrategy
    class EmptyStrategy

      def job_enqueued(job_id)
      end

      def job_started(job_id)
      end

      def job_finished(job_id)
      end

      def find(job_id)
      end

      def completed?(job_id)
      end

      def meta(job_id)
        {}
      end

    end
  end
end

# strategy_spy_mock = Spy.mock(Immortus::EmptyStrategy)
# Spy.on(strategy_spy_mock, :job_enqueued).and_call_through
# Spy.on(strategy_spy_mock, :job_started).and_call_through
# Spy.on(strategy_spy_mock, :job_finished).and_call_through
# Spy.on(strategy_spy_mock, :find).and_call_through
# Spy.on(strategy_spy_mock, :status).and_call_through
