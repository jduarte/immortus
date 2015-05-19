module Immortus
  module TrackingStrategy
    class DelayedJobActiveRecordStrategy
      def job_enqueued(job_id)
      end

      def job_started(job_id)
      end

      def job_finished(job_id)
      end

      def status(job_id)
        job = find(job_id)

        # Whenever a job is deleted DelayedJob will delete that record from the DB
        return :finished if !job

        # If a job has started perform or has previous attempts it will return :started
        return :started if job.locked_at || job.attempts > 0
        return :created
      end

      private

      def find(job_id)
        ::Delayed::Job.where("handler LIKE ?", "%#{job_id}%").first
      end
    end
  end
end
