# frozen_string_literal: true

module Kiev
  module Sidekiq
    class StoreRequestDetails
      JID = "jid"
      WRAPPED = "wrapped"

      def call(worker, job, _queue)
        Config.instance.jobs_propagated_fields.each do |key|
          Kiev[key] = job[key.to_s]
        end
        request_store = Kiev::RequestStore.store
        request_store[:background_job] = true
        request_store[:job_name] = expand_worker_name(worker, job)
        request_store[:jid] = job[JID]
        yield
      end

      private

      def expand_worker_name(worker, job)
        job[WRAPPED] || worker.class.name
      end
    end
  end
end
