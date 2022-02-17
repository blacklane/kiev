# frozen_string_literal: true

require "request_store"
require "ruby_dig"
require_relative "request_store"
require_relative "request_logger"
require_relative "logger"
require_relative "param_filter"
require_relative "request_body_filter"
require_relative "json"
require_relative "version"
require_relative "config"
require_relative "util"
require_relative "subrequest_helper"
require_relative "hanami"
require "forwardable"
require "logger"

module Kiev
  class << self
    extend Forwardable

    def_delegators :config,
                   :logger,
                   :filtered_params,
                   :ignored_params,
                   :log_level,
                   :disable_filter_for_log_levels

    EMPTY_OBJ = {}.freeze

    def configure
      yield(Config.instance)
    end

    def config
      Config.instance
    end

    def event(log_name, data = EMPTY_OBJ, severity = log_level)
      logger.log(severity, logged_data(data), log_name)
    end

    Config.instance.supported_log_levels.each_pair do |key, value|
      define_method(key) do |log_name, data = EMPTY_OBJ|
        event(log_name, data, value)
      end
    end

    def []=(name, value)
      RequestStore.store[:payload] ||= {}
      RequestStore.store[:payload][name] = value
    end

    def payload(data)
      raise ArgumentError, "Hash expected" unless data.is_a?(Hash)

      RequestStore.store[:payload] ||= {}
      RequestStore.store[:payload].merge!(data)
    end

    def error=(value)
      RequestStore.store[:error] = value
    end

    def request_id
      RequestStore.store[:tracking_id]
    end

    alias_method :tracking_id, :request_id

    private

    def logged_data(data)
      return data if disable_filter_for_log_levels.include?(log_level)

      ParamFilter.filter(data, filtered_params, ignored_params)
    end
  end
end
