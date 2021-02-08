# frozen_string_literal: true

require "bundler"
require "delegate"

Bundler.require :default, :development
require "rack/test" if defined?(Rack)

require "helpers/log_helper"

if defined?(::Que::Job)
  require "helpers/que_helper"
end
