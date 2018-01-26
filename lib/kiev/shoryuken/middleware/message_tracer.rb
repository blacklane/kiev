# frozen_string_literal: true

module Kiev
  module Shoryuken
    module Middleware
      class MessageTracer
        def call(options)
          attrbutes = options[:message_attributes] ||= {}
          SubrequestHelper.payload.each do |key, value|
            attrbutes[key] = {
              data_type: "String",
              string_value: value.to_s
            }
          end
          yield
        end
      end
    end
  end
end
