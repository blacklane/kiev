# frozen_string_literal: true

module Kiev
  module Sidekiq
    class RequestLogger
      NEW_LINE = "\n"
      ARGS = "args"

      def call(_worker, job, _queue)
        began_at = Time.now
        error = nil

        begin
          return_value = yield
        rescue Exception => exception
          error = exception
        end

        begin
          data = {
            params: job[ARGS],
            request_duration: ((Time.now - began_at) * 1000).round(3)
          }

          if error
            data[:error_class] = error.class.name
            data[:error_message] = error.message[0..5000]
            data[:error_backtrace] = Array(error.backtrace).join(NEW_LINE)[0..5000]
          end

          Kiev.event(:job_finished, data)
        ensure
          raise error if error
          return_value
        end
      end
    end
  end
end
