# frozen_string_literal: true

require_relative "base52"

module Kiev
  class SubrequestHelper
    class << self
      def headers(metadata: false)
        Config.instance.all_http_propagated_fields.map do |key, http_key|
          field = field_value(key, true)
          [metadata ? key : http_key, field.to_s] if field
        end.compact.to_h
      end

      def payload
        Config.instance.all_jobs_propagated_fields.map do |key|
          field = field_value(key, false)
          [key.to_s, field] if field
        end.compact.to_h
      end

      def root_path(synchronous:)
        encode(0, synchronous)
      end

      def subrequest_path(synchronous:)
        current_path + encode(counter, synchronous)
      end

      private

      def field_value(key, synchronous)
        if key == :tree_path
          subrequest_path(synchronous:)
        else
          request_store = Kiev::RequestStore.store
          request_store[key] || request_store.dig(:payload, key)
        end
      end

      def encode(value, synchronous)
        # this scheme can encode up to 26 consequent requests (synchronous or asynchronous)
        Base52.encode(value * 2 + (synchronous ? 0 : 1))
      end

      def current_path
        RequestStore.store[:tree_path] || ""
      end

      def counter
        if RequestStore.store[:subrequest_count]
          # generally this is not atomic operation,
          # but because RequestStore.store is tied to current thread this is ok
          RequestStore.store[:subrequest_count] += 1
        else
          RequestStore.store[:subrequest_count] = 0
        end
      end
    end
  end
end
