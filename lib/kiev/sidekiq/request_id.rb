# frozen_string_literal: true

require "securerandom"
require "kiev/request_id"
require "kiev/context_reader"

module Kiev
  module Sidekiq
    class RequestId
      include Kiev::RequestId::Mixin

      def call(_worker, job, _queue, &block)
        context_reader = Kiev::ContextReader.new(job)
        wrap_request_id(context_reader, &block)
      end
    end
  end
end
