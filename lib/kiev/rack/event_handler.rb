# frozen_string_literal: true

module Kiev
  module Rack
    class EventHandler
      include ::Rack::Events::Abstract

      def on_start(_request, _)
        span_id, trace_id = span_and_trade_ids
        Kiev::RequestStore.store[:trace_id] = trace_id
        Kiev::RequestStore.store[:span_id] = span_id
      end

      private

      def span_and_trade_ids
        return [nil, nil] unless defined?(OpenTelemetry::Trace) && defined?(OpenTelemetry::Context)

        span = OpenTelemetry::Trace.current_span(OpenTelemetry::Context.current).context
        return [nil, nil] if span.nil? || !span.valid?

        [
          span.trace_id.unpack1("H*")[16, 16].to_i(16).to_s,
          span.trace_id.unpack1("H*")[16, 16].to_i(16).to_s
        ]
      end
    end
  end
end
