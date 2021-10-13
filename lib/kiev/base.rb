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

module Kiev
  class << self
    EMPTY_OBJ = {}.freeze

    def configure
      yield(Config.instance)
    end

    def logger
      Config.instance.logger
    end

    def filtered_params
      Config.instance.filtered_params
    end

    def ignored_params
      Config.instance.ignored_params
    end

    def event(event_name, data = EMPTY_OBJ)
      filtered_data = if data.respond_to?(:each_with_object)
        ParamFilter.filter(data, filtered_params, ignored_params)
      else
        data
      end

      logger.log(
        ::Logger::Severity::INFO,
        filtered_data,
        event_name
      )
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
  end
end
