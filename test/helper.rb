# frozen_string_literal: true

require "bundler"

Bundler.require :default, :development

require "rack/test"
require "minitest"
require "minitest/autorun"
require "minitest/reporters"

reporter_options = { color: true }
Minitest::Reporters.use!([Minitest::Reporters::DefaultReporter.new(reporter_options)])

LOG_IO = StringIO.new
ROOT_FOLDER = File.expand_path(File.dirname(__FILE__)).to_s.freeze
DATA_FOLDER = "#{ROOT_FOLDER}/data"

require "json"
module LogHelper
  def setup
    reset_logs
    super
  end

  def reset_logs
    LOG_IO.rewind
    LOG_IO.truncate(0)
    @logs = nil
  end

  def logs
    return @logs if @logs
    LOG_IO.rewind
    raw_logs = LOG_IO.read
    begin
      @logs = raw_logs.split("\n").map(&JSON.method(:parse))
    rescue
      puts raw_logs
      raise
    end
  end

  def log_first
    logs.first
  end

  def log_last
    logs.last
  end
end

class KievIgnoredException < StandardError; end

Kiev.configure do |c|
  c.log_path = LOG_IO
  c.log_request_body_condition = proc do |request, _response|
    !!(request.content_type =~ /(application|text)\/(xml|json)/)
  end
  c.propagated_fields = {
    special_field: "Special-Field"
  }
  c.ignored_rack_exceptions << "KievIgnoredException"
end

if defined?(Combustion)
  require "rails/test_help"
  # Rails.env = "production"
  Combustion.path = "test/rails_app"
  Combustion.initialize!(:action_controller, :active_record) do
    config.action_dispatch.show_exceptions = false
    config.consider_all_requests_local     = false
    config.active_support.test_order       = :random
    # middleware to parse XML request body
    config.middleware.swap(
      ActionDispatch::ParamsParser, ActionDispatch::ParamsParser,
      Mime::XML => proc do |raw_post|
        Hash.from_xml(raw_post)
      end
    )
  end
end

if defined?(Sinatra)
  require "sinatra_app/test_app"
end

if defined?(Sidekiq)
  $TESTING = true
  require "sidekiq/processor"

  Sidekiq.logger.level = Logger::ERROR

  REDIS_URL = ENV["REDIS_URL"] || "redis://localhost/15"
  REDIS = Sidekiq::RedisConnection.create(url: REDIS_URL)

  Kiev::Sidekiq.enable
  Sidekiq.configure_client do |config|
    config.redis = { url: REDIS_URL }
    # this is required because we do not run server in the tests
    # so we configure server_middleware for **client**
    Kiev::Sidekiq.enable_server_middleware(config)
  end
end

begin
  require "faraday"
rescue LoadError
  puts "No Faraday"
end
