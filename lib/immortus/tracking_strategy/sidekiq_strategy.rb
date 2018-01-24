module Immortus
  module TrackingStrategy
    class SidekiqStrategy
      def completed?(job_id)
        job = find(job_id)
        job.blank?
      end

      private

        def find(job_id)
          found_job = nil
          queues = Sidekiq::Queue.all.map(&:name).each do |queue|
            break if found_job
            Sidekiq::Queue.new(queue).each do |job|
              break if found_job
              next unless job.item["args"].first["job_id"] == job_id
              found_job = job
            end
          end
          found_job
        end
    end
  end
end
