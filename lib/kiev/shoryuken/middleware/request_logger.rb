# frozen_string_literal: true

module Kiev
  module Shoryuken
    module Middleware
      class RequestLogger
        include Kiev::RequestLogger::Mixin

        def call(_worker, _queue, _message, body, &block)
          wrap_request_logger(:job_finished, body: body, &block)
        end
      end
    end
  end
end
