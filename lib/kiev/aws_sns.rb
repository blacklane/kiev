# frozen_string_literal: true

require_relative "base"

module Kiev
  module AwsSns
    require_relative "kafka/context_injector"

    class << self
      # @param [Hash] headers
      def inject_context(headers = {})
        Kiev::AwsSns::ContextInjector.new.call(headers)
      end
    end
  end
end
