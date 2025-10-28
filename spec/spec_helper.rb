# frozen_string_literal: true

require "logger"
require "bundler"
require "delegate"

Bundler.require :default, :development
require "rack/test" if defined?(Rack)

require "helpers/log_helper"

if defined?(::Que::Job)
  require "helpers/que_helper"
end

RSpec.configure do |config|
  config.expect_with :rspec do |c|
    c.max_formatted_output_length = nil # Don't truncate output
  end
end

begin
  require "bigdecimal"
  # Ensure consistent BigDecimal string output across environments
  # for deterministic tests
  BigDecimal.limit(18) if BigDecimal.respond_to?(:limit)
rescue LoadError
  # BigDecimal may not be present in some environments; ignore
end
