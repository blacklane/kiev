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
        credit_card_valid_date
        caption
        CardNumber
        CardCVV
        CardExpires
        new_booker_first_name
        new_booker_last_name
        new_booker_email
        new_booker_mobile_phone
        new_passenger_first_name
        new_passenger_last_name
        new_passenger_email
        new_passenger_mobile_phone
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

    attr_accessor :app,
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
                :http_propagated_fields,
                :jobs_propagated_fields,
                :all_http_propagated_fields, # for internal use
                :all_jobs_propagated_fields # for internal use

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
      @log_level = nil
      @persistent_log_fields = []
      @pre_rack_hook = DEFAULT_PRE_RACK_HOOK
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
      @log_level = value
      update_logger_settings
    end

    def development_mode=(value)
      @development_mode = value
      update_logger_settings
    end

    private

    def update_logger_settings
      @logger.formatter = formatter
      @logger.level = @log_level || default_log_level
    end

    def formatter
      development_mode ? Logger::DEVELOPMENT_FORMATTER : Logger::FORMATTER
    end

    def default_log_level
      development_mode ? ::Logger::DEBUG : ::Logger::INFO
    end
  end
end
