# frozen_string_literal: true

module Kiev
  module Rack
    class OpenTelemetryTracesDatadogCorrelation
      # https://docs.datadoghq.com/tracing/other_telemetry/connect_logs_and_traces/opentelemetry/?tab=ruby

      def initialize(app)
        @app = app
      end

      def call(env)
        if current_span
          RequestStore.store[:otel_dd_correlation] = true
          RequestStore.store["dd.env"] = Config.instance.app_env
          RequestStore.store["dd.service"] = Config.instance.app
          RequestStore.store["dd.trace_id"] = datadog_trace_id
          RequestStore.store["dd.span_id"] = datadog_span_id
        end

        @app.call(env)
      end

      private

      def datadog_trace_id
        current_span&.trace_id.unpack1('H*')[16, 16].to_i(16).to_s
      end

      def datadog_span_id
        current_span&.span_id.unpack1('H*').to_i(16).to_s
      end

      def current_span
        OpenTelemetry::Trace.current_span(OpenTelemetry::Context.current).context
      rescue
        nil
      end
    end
  end
end
