# frozen_string_literal: true


require_relative "message_context"
require "kiev/request_id"
require "kiev/context_reader"

module Kiev
  module Kafka
    class ContextInjector
      include Kiev::RequestId::Mixin

      # @param [Hash] headers Injects context headers
      # @return [Hash]
      def call(headers = {})
        Kiev::SubrequestHelper.payload.each do |key, value|
          field_key = Kiev::Config::DEFAULT_HTTP_PROPAGATED_FIELDS.fetch(key.to_sym, key)
          headers[field_key] = value
        end
        headers
      end
    end
  end
end
