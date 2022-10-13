# frozen_string_literal: true

require_relative "base"
require_relative "rack/request_logger"
require_relative "rack/request_id"
require_relative "rack/store_request_details"
require_relative "rack/silence_action_dispatch_logger"
require_relative "rack/open_telemetry_traces_datadog_correlation"
require_relative "../ext/rack/common_logger"

module Kiev
  module Rack
    def self.included(base)
      # The order is important
      base.use(::RequestStore::Middleware)
      base.use(Kiev::Rack::RequestLogger)
      base.use(Kiev::Rack::StoreRequestDetails)
      base.use(Kiev::Rack::RequestId)
      base.use(Kiev::Rack::OpenTelemetryTracesDatadogCorrelation)
    end
  end
end
