# frozen_string_literal: true

require "singleton"

module Kiev
  class Config
    include Singleton

    DEFAULT_LOG_REQUEST_REGEXP = %r{(^(/ping|/health))|(\.(js|css|png|jpg|gif|ico|svg)$)}
    private_constant :DEFAULT_LOG_REQUEST_REGEXP

    DEFAULT_LOG_REQUEST_CONDITION = proc do |request, _response|
      !DEFAULT_LOG_REQUEST_REGEXP.match(request.path)
    end

    DEFAULT_LOG_REQUEST_ERROR_CONDITION = proc do |_request, response|
      response.status != 404
    end

    DEFAULT_LOG_RESPONSE_BODY_REGEXP = /(json|xml)/
    private_constant :DEFAULT_LOG_RESPONSE_BODY_REGEXP

    DEFAULT_LOG_RESPONSE_BODY_CONDITION = proc do |_request, response|
      !!(response.status >= 400 && response.status < 500 && response.content_type =~ DEFAULT_LOG_RESPONSE_BODY_REGEXP)
    end

    DEFAULT_LOG_REQUEST_BODY_CONDITION = proc do |request, _response|
      !!(request.content_type =~ /(application|text)\/xml/)
    end

    DEFAULT_IGNORED_RACK_EXCEPTIONS =
      %w(
        ActiveRecord::RecordNotFound
        Mongoid::Errors::DocumentNotFound
        Sequel::RecordNotFound
      ).freeze

    FILTERED_PARAMS =
      %w(
        client_secret
        token
        password
        password_confirmation
        old_password
        credit_card_number
        credit_card_cvv
        credit_card_holder
        credit_card_expiry_month
        credit_card_expiry_year
        CardNumber
        CardCVV
        CardExpires
      ).freeze

    IGNORED_PARAMS =
      (%w(
        controller
        action
        format
        authenticity_token
        utf8
        tempfile
      ) << :tempfile).freeze

    DEFAULT_HTTP_PROPAGATED_FIELDS = {
      tracking_id: "X-Tracking-Id",
      request_id: "X-Request-Id",
      request_depth: "X-Request-Depth",
      tree_path: "X-Tree-Path"
    }.freeze

    DEFAULT_PRE_RACK_HOOK = proc do |env|
      Config.instance.http_propagated_fields.each do |key, http_key|
        Kiev[key] = Util.sanitize(env[Util.to_http(http_key)])
      end
    end

    SUPPORTED_LOG_LEVELS = {
      debug: ::Logger::DEBUG,
      info: ::Logger::INFO,
      warn: ::Logger::WARN,
      error: ::Logger::ERROR,
      fatal: ::Logger::FATAL
    }.freeze

    private_constant :SUPPORTED_LOG_LEVELS

    attr_accessor :app,
                  :app_env,
                  :log_request_condition,
                  :log_request_error_condition,
                  :log_response_body_condition,
                  :log_request_body_condition,
                  :filtered_params,
                  :ignored_params,
                  :ignored_rack_exceptions,
                  :disable_default_logger,
                  :persistent_log_fields,
                  :pre_rack_hook

    attr_reader :development_mode,
                :logger,
                :log_level,
                :http_propagated_fields,
                :jobs_propagated_fields,
                :all_http_propagated_fields, # for internal use
                :all_jobs_propagated_fields, # for internal use
                :disable_filter_for_log_levels

    def initialize
      @log_request_condition = DEFAULT_LOG_REQUEST_CONDITION
      @log_request_error_condition = DEFAULT_LOG_REQUEST_ERROR_CONDITION
      @log_response_body_condition = DEFAULT_LOG_RESPONSE_BODY_CONDITION
      @log_request_body_condition = DEFAULT_LOG_REQUEST_BODY_CONDITION
      @filtered_params = FILTERED_PARAMS
      @ignored_params = IGNORED_PARAMS
      @disable_default_logger = true
      @development_mode = false
      @ignored_rack_exceptions = DEFAULT_IGNORED_RACK_EXCEPTIONS.dup
      @logger = Kiev::Logger.new(STDOUT)
      @log_level = default_log_level
      @persistent_log_fields = []
      @pre_rack_hook = DEFAULT_PRE_RACK_HOOK
      @disable_filter_for_log_levels = []
      self.propagated_fields = {}
      update_logger_settings
    end

    def http_propagated_fields=(value)
      @all_http_propagated_fields = DEFAULT_HTTP_PROPAGATED_FIELDS.merge(value)
      @http_propagated_fields = @all_http_propagated_fields.dup
      DEFAULT_HTTP_PROPAGATED_FIELDS.keys.each do |key|
        @http_propagated_fields.delete(key)
      end
      @http_propagated_fields.freeze
    end

    def jobs_propagated_fields=(value)
      @all_jobs_propagated_fields = (DEFAULT_HTTP_PROPAGATED_FIELDS.keys + value).uniq.freeze
      @jobs_propagated_fields = (@all_jobs_propagated_fields - DEFAULT_HTTP_PROPAGATED_FIELDS.keys).freeze
    end

    # shortcut
    def propagated_fields=(value)
      self.http_propagated_fields = value
      self.jobs_propagated_fields = value.keys
    end

    def log_path=(value)
      logger.path = value
      update_logger_settings
    end

    def log_level=(value)
      raise ArgumentError, "Unsupported log level #{value}" unless supported_log_level?(value)

      @log_level = value
      update_logger_settings
    end

    def disable_filter_for_log_levels=(log_levels)
      raise ArgumentError, "Unsupported log levels" unless array_with_log_levels?(log_levels)

      @disable_filter_for_log_levels = log_levels
    end

    def development_mode=(value)
      @development_mode = value
      update_logger_settings
    end

    def supported_log_levels
      SUPPORTED_LOG_LEVELS
    end

    def filter_enabled?
      !disable_filter_for_log_levels.include?(log_level)
    end

    private

    def update_logger_settings
      @logger.formatter = formatter
      @logger.level = @log_level
    end

    def formatter
      development_mode ? Logger::DEVELOPMENT_FORMATTER : Logger::FORMATTER
    end

    def default_log_level
      development_mode ? ::Logger::DEBUG : ::Logger::INFO
    end

    def array_with_log_levels?(log_levels)
      return false unless log_levels.is_a?(Array)

      log_levels.all? { |level| supported_log_level?(level) }
    end

    def supported_log_level?(log_level)
      supported_log_levels.value?(log_level)
    end
  end
end
