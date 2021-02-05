# frozen_string_literal: true

require "kiev/aws_sns/context_injector"

module Kiev
  module Shoryuken
    module Middleware
      class MessageTracer
        def call(options)
          options[:message_attributes] ||= {}
          Kiev::AwsSns::ContextInjector.new.call(options[:message_attributes])
          yield
        end
      end
    end
  end
end
