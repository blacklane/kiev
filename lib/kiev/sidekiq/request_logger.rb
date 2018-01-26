# frozen_string_literal: true

module Kiev
  module Sidekiq
    class RequestLogger
      include Kiev::RequestLogger::Mixin

      ARGS = "args"

      def call(_worker, job, _queue, &block)
        wrap_request_logger(:job_finished, params: job[ARGS], &block)
      end
    end
  end
end
