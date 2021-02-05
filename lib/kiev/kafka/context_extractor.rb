# frozen_string_literal: true


require_relative "message_context"
require "kiev/request_id"
require "kiev/context_reader"

module Kiev
  module Kafka
    class ContextExtractor
      include Kiev::RequestId::Mixin

      # @param [Kafka::FetchedMessage] message
      def call(message)
        context = Kiev::Kafka::MessageContext.new(message)
        context_reader = Kiev::ContextReader.new(context)
        wrap_request_id(context_reader) {}

        Kiev[:message_key] = message.key

        Config.instance.jobs_propagated_fields.each do |key|
          Kiev[key] = context_reader[key]
        end
      end
    end
  end
end
