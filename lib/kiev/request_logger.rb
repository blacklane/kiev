# frozen_string_literal: true

module Kiev
  module RequestLogger
    module Mixin
      NEW_LINE = "\n"
      LOG_ERROR = "ERROR"

      def wrap_request_logger(event, **data, &_block)
        began_at = Time.now
        error = nil

        begin
          return_value = yield
        rescue StandardError => exception
          error = exception
        end

        begin
          data[:request_duration] = ((Time.now - began_at) * 1000).round(3)
          if error
            data[:error_class] = error.class.name
            data[:error_message] = error.message[0..5000]
            data[:error_backtrace] = Array(error.backtrace).join(NEW_LINE)[0..5000]
            data[:level] = LOG_ERROR
          end

          Kiev.event(event, data)
        ensure
          raise error if error
          return_value
        end
      end
    end
  end
end
