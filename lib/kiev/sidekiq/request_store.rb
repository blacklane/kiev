# frozen_string_literal: true

module Kiev
  module Sidekiq
    class RequestStore
      include Sidekiq::ServerMiddleware
      include Kiev::RequestStore::Mixin

      def call(_worker, _job, _queue, &block)
        wrap_request_store(&block)
      end
    end
  end
end
