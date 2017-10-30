# frozen_string_literal: true

module Kiev
  module Sidekiq
    class ClientRequestId
      def call(_worker_class, job, _queue, _redis_pool)
        job.merge!(SubrequestHelper.payload)
        yield
      end
    end
  end
end
