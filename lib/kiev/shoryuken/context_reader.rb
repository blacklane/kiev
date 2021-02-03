# frozen_string_literal: true

require "kiev/context_reader"

module Kiev
  module Shoryuken
    class ContextReader < Kiev::ContextReader
      def initialize(message)
        super
        @message_attributes = message.message_attributes
      end

      def [](key)
        return unless @message_attributes.key?(key)

        attribute_value = @message_attributes[key]
        return unless attribute_value.data_type == "String"

        attribute_value.string_value
      end
    end
  end
end
