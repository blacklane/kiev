# frozen_string_literal: true

require_relative "../base"

module Kiev
  module Que
    # Original implementation https://github.com/chanks/que/blob/master/lib/que/job.rb
    class Job < ::Que::Job
      include Kiev::RequestStore::Mixin

      def self.enqueue(*args)
        if ::Que.mode == :async
          super(*args.unshift(SubrequestHelper.payload))
        else
          super
        end
      end

      def _run
        if ::Que.mode == :async
          wrap_request_store { kiev_run }
        else
          kiev_run
        end
      end

      private

      NEW_LINE = "\n"
      LOG_ERROR = "error"

      def kiev_run
        args = attrs[:args]
        payload = {}

        if args.first.is_a?(Hash)
          options = args.shift
          payload = Config.instance.all_jobs_propagated_fields.map do |key|
            # sometimes JSON decoder is overridden and it can be instructed to symbolize keys
            [key, options.delete(key.to_s) || options.delete(key)]
          end.to_h
          args.unshift(options) if options.any?
        end

        if ::Que.mode == :async
          Config.instance.jobs_propagated_fields.each do |key|
            Kiev[key] = payload[key]
          end
          request_store = Kiev::RequestStore.store
          request_store[:request_id] = payload[:request_id]
          request_store[:request_depth] = payload[:request_depth].to_i + 1
          request_store[:tree_path] = payload[:tree_path]

          request_store[:background_job] = true
          request_store[:job_name] = attrs[:job_class]
        end

        began_at = Time.now

        ::Que::Job.instance_method(:_run).bind(self).call

        data = {
          params: attrs[:args],
          request_duration: ((Time.now - began_at) * 1000).round(3)
        }

        error ||= _error

        if error
          data[:error_class] = error.class.name
          data[:error_message] = error.message[0..5000]
          data[:error_backtrace] = Array(error.backtrace).join(NEW_LINE)[0..5000]
          data[:level] = LOG_ERROR
        end

        Kiev.event(:job_finished, data)
      end
    end
  end
end
