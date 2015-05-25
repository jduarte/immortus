module Immortus
  module TrackingStrategy
    class DelayedJobActiveRecordStrategy

      def completed?(job_id)
        job = find(job_id)

        return !job
      end

      private

      def find(job_id)
        ::Delayed::Job.where("handler LIKE ?", "%#{job_id}%").first
      end
    end
  end
end
