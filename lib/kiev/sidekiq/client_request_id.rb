# frozen_string_literal: true

module Kiev
  module Sidekiq
    class ClientRequestId
      include ::Sidekiq::ClientMiddleware if defined?(::Sidekiq::ClientMiddleware)

      def call(_worker_class, job, _queue, _redis_pool)
        job.merge!(SubrequestHelper.payload)
        yield
      end
    end
  end
end
