module Immortus
  module TrackingStrategy
    class DelayedJobStrategy
      def job_enqueued(job_id)
      end

      def job_started(job_id)
      end

      def job_finished(job_id)
      end

      def find(job_id)
        Delayed::Job.where("handler LIKE ?", "%#{job_id}%").first
      end

      def status(job_id)
        tracker = find(job_id)

        return :finished_success if !tracker
        return :finished_error if tracker.attempts > 0
        return :started if tracker.locked_at
        return :created
      end
    end
  end
end
