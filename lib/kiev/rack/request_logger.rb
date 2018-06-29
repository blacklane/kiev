# frozen_string_literal: true

module Kiev
  module Rack
    class RequestLogger
      ERROR_STATUS = 500
      ERROR_HEADERS = [].freeze
      ERROR_BODY = [""].freeze

      def initialize(app)
        @app = app
      end

      def call(env)
        rescued_exception = nil
        began_at = Time.now.to_f

        request = ::Rack::Request.new(env)

        begin
          status, headers, body = @app.call(env)
        rescue Exception => e
          rescued_exception = e

          status = ERROR_STATUS
          headers = ERROR_HEADERS
          body = ERROR_BODY

          if defined?(ActionDispatch::ExceptionWrapper)
            status = ::ActionDispatch::ExceptionWrapper.status_code_for_exception(rescued_exception.class.name)
          end
        end

        response = ::Rack::Response.new(body, status, headers)

        rack_exception = log_rack_exception?(env[SINATRA_ERROR]) ? env[SINATRA_ERROR] : nil
        log_exception = RequestStore.store[:error]
        exception = rescued_exception || rack_exception || log_exception

        if exception || Config.instance.log_request_condition.call(request, response)
          Kiev.event(
            :request_finished,
            form_data(
              began_at: began_at,
              env: env,
              request: request,
              response: response,
              status: status,
              body: body,
              exception: exception
            )
          )
        end

        raise rescued_exception if rescued_exception

        [status, headers, body]
      end

      private

      HTTP_USER_AGENT = "HTTP_USER_AGENT"
      ACTION_REQUEST_PARAMETERS = "action_dispatch.request.request_parameters"
      ACTION_QUERY_PARAMETERS = "action_dispatch.request.query_parameters"
      NEW_LINE = "\n"
      HTTP_X_REQUEST_START = "HTTP_X_REQUEST_START"
      SINATRA_ERROR = "sinatra.error"

      def log_rack_exception?(exception)
        !Config.instance.ignored_rack_exceptions.include?(exception.class.name)
      end

      def form_data(request:, began_at:, status:, env:, body:, response:, exception:)
        config = Config.instance

        params =
          if env[ACTION_REQUEST_PARAMETERS] && env[ACTION_QUERY_PARAMETERS]
            env[ACTION_REQUEST_PARAMETERS].merge(env[ACTION_QUERY_PARAMETERS])
          elsif env[ACTION_REQUEST_PARAMETERS]
            env[ACTION_REQUEST_PARAMETERS]
          else
            request.params
          end

        params = ParamFilter.filter(params, config.filtered_params, config.ignored_params)

        data = {
          http_host: request.host, # env["HTTP_HOST"] || env["HTTPS_HOST"],
          params: params.empty? ? nil : params, # env[Rack::QUERY_STRING],
          ip: request.ip, # split_http_x_forwarded_headers(env) || env["REMOTE_ADDR"]
          user_agent: env[HTTP_USER_AGENT],
          status: status,
          request_duration: ((Time.now.to_f - began_at) * 1000).round(3),
          route: extract_route(env)
        }

        if env[HTTP_X_REQUEST_START]
          data[:request_latency] = ((began_at - env[HTTP_X_REQUEST_START].to_f) * 1000).round(3)
        end

        if config.log_request_body_condition.call(request, response)
          data[:request_body] =
            RequestBodyFilter.filter(
              request.content_type,
              request.body,
              config.filtered_params,
              config.ignored_params
            )
        end

        if config.log_response_body_condition.call(request, response)
          # it should always respond to each, but this code is not streaming friendly
          full_body = []
          body.each do |str|
            full_body << str
          end
          data[:body] = full_body.join
        end

        should_log_errors = config.log_request_error_condition.call(request, response)
        if should_log_errors && exception.is_a?(Exception)
          data[:error_class] = exception.class.name
          data[:error_message] = exception.message[0..5000]
          data[:error_backtrace] = Array(exception.backtrace).join(NEW_LINE)[0..5000]
        end

        data
      end

      def extract_route(env)
        action_params = env["action_dispatch.request.parameters"]
        if action_params
          "#{action_params['controller']}##{action_params['action']}"
        else
          env["sinatra.route"]
        end
      end
    end
  end
end
