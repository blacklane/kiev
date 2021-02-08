# frozen_string_literal: true

module Kiev
  module Kafka
    class MessageContext
      # @param [Kafka::FetchedMessage] message
      def initialize(message)
        @headers = message.headers
      end

      def value(field)
        headers[header_key(field)] || headers[field.to_s]
      end

      alias_method :[], :value

      private

      attr_reader :headers

      # @param [String] field
      def header_key(field)
        "x_#{field}".gsub("_", " ").split.map(&:capitalize).join("-")
      end
    end
  end
end
