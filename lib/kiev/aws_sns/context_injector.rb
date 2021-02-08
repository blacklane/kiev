# frozen_string_literal: true

require "kiev/config"
require "kiev/subrequest_helper"

module Kiev
  module AwsSns
    class ContextInjector
      # @param [Hash] message_attributes Injects context headers
      # @return [Hash]
      def call(message_attributes = {})
        Kiev::SubrequestHelper.payload.each do |key, value|
          message_attributes[key] = {
            data_type: "String",
            string_value: value.to_s
          }
        end
        message_attributes
      end
    end
  end
end
