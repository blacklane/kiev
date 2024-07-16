# frozen_string_literal: true

require "opentelemetry/sdk"
require "opentelemetry/instrumentation/rails"

OpenTelemetry::SDK.configure do |c|
  c.service_name = "test-app"
  c.use_all() # enables all instrumentation!
end
