# frozen_string_literal: true

require "logger"
require "time"
require "forwardable"

# Keep this class minimal and compatible with Ruby Logger.
# If you add custom methods to this class and they will be used by developer,
# it will be hard to swap this class with any other Logger implementation.
module Kiev
  class Logger
    extend Forwardable
    def_delegators(*([:@logger] + ::Logger.instance_methods(false)))

    DEFAULT_EVENT_NAME = "log"
    LOG_ERROR = "ERROR"
    ERROR_STATUS = 500

    FORMATTER = proc do |severity, time, event_name, data|
      entry =
        {
          application: Config.instance.app,
          event: event_name || DEFAULT_EVENT_NAME,
          level: severity,
          timestamp: time.utc,
          tracking_id: RequestStore.store[:tracking_id],
          request_id: RequestStore.store[:request_id],
          request_depth: RequestStore.store[:request_depth],
          tree_path: RequestStore.store[:tree_path]
        }

      # data required to restore source of log entry
      if RequestStore.store[:web]
        entry[:verb] = RequestStore.store[:request_verb]
        entry[:path] = RequestStore.store[:request_path]
      end
      if RequestStore.store[:background_job]
        entry[:job_name] = RequestStore.store[:job_name]
        entry[:jid] = RequestStore.store[:jid]
      end

      if !RequestStore.store[:subrequest_count] && %i(request_finished job_finished).include?(event_name)
        entry[:tree_leaf] = true
      end

      if RequestStore.store[:payload]
        if %i(request_finished job_finished).include?(event_name)
          entry.merge!(RequestStore.store[:payload])
        else
          Config.instance.persistent_log_fields.each do |field|
            entry[field] = RequestStore.store[:payload][field]
          end
        end
      end

      if data.is_a?(Hash)
        entry.merge!(data)
      elsif !data.nil?
        entry[:message] = data.to_s
        entry[:status] = ERROR_STATUS if data.to_s.downcase.include?(LOG_ERROR)
      end

      entry[:level] = LOG_ERROR if entry[:status].to_i.between?(400, 599)

      # Save some disk space
      entry.reject! { |_, value| value.nil? }

      JSON.logstash(entry)
    end

    DEVELOPMENT_FORMATTER = proc do |severity, time, event_name, data|
      entry = []

      entry << time.iso8601
      entry << (event_name || severity).upcase

      if data.is_a?(String)
        entry << "#{data}\n"
      end

      if %i(request_finished job_finished).include?(event_name)
        verb = RequestStore.store[:request_verb]
        path = RequestStore.store[:request_path]
        entry << "#{verb} #{path}" if verb && path

        job_name = RequestStore.store[:job_name]
        jid = RequestStore.store[:jid]
        entry << "#{job_name} #{jid}" if job_name && jid

        status = data.is_a?(Hash) ? data.delete(:status) : nil
        entry << "- #{status}" if status
        duration = data.is_a?(Hash) ? data.delete(:request_duration) : nil
        entry << "(#{duration}ms)" if duration
        entry << "\n"

        meta = {
          tracking_id: RequestStore.store[:tracking_id],
          request_id: RequestStore.store[:request_id],
          request_depth: RequestStore.store[:request_depth]
        }.reverse_merge!(Hash(RequestStore.store[:payload]))

        meta.reject! { |_, value| value.nil? }

        entry << "  Meta: #{meta.inspect}\n"

        entry << "  Params: #{data[:params].inspect}\n" if data.is_a?(Hash) && data[:params]

        if data.is_a?(Hash) && data[:body]
          entry << "  Response: #{data[:body]}\n"
        end
      end

      entry.join(" ")
    end

    def initialize(log_path)
      @logger = ::Logger.new(log_path)
    end

    def path=(log_path)
      previous_logger = @logger
      @logger = ::Logger.new(log_path)
      if previous_logger
        @logger.level = previous_logger.level
        @logger.formatter = previous_logger.formatter
      end
    end
  end
end
