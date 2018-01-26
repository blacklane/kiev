# frozen_string_literal: true

require "securerandom"
require "kiev/request_id"
require "kiev/shoryuken/context_reader"

module Kiev
  module Shoryuken
    module Middleware
      class RequestId
        include Kiev::RequestId::Mixin

        def call(_worker, _queue, message, _body, &block)
          context_reader = Kiev::Shoryuken::ContextReader.new(message)
          wrap_request_id(context_reader, &block)
        end
      end
    end
  end
end
