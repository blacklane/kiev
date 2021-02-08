# frozen_string_literal: true

require_relative "base"

module Kiev
  module Kafka
    require_relative "kafka/context_extractor"
    require_relative "kafka/context_injector"

    class << self
      # @param [Kafka::FetchedMessage] message
      def extract_context(message)
        Kiev::Kafka::ContextExtractor.new.call(message)
      end

      # @param [Hash] headers
      def inject_context(headers = {})
        Kiev::Kafka::ContextInjector.new.call(headers)
      end
    end
  end
end
