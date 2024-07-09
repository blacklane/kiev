# frozen_string_literal: true

module Kiev
  module Rack
    class TraceId
      def initialize(app)
        @app = app
      end

      def call(env)
        RequestStore.store[:trace_id] = trace_id
        @app.call(env)
      end

      private

      def trace_id
        return unless defined?(OpenTelemetry::Trace) && defined?(OpenTelemetry::Context)

        span = OpenTelemetry::Trace.current_span(OpenTelemetry::Context.current).context
        return unless span.nil? || !span.valid?

        span.trace_id.unpack1("H*")[16, 16].to_i(16).to_s
      end
    end
  end
end
