# frozen_string_literal: true

require_relative "base"

module Kiev
  module Shoryuken
    require_relative "shoryuken/middleware"

    class << self
      def enable(base = nil)
        base ||= ::Shoryuken
        base.configure_client do |config|
          enable_client_middleware(config)
        end
        base.configure_server do |config|
          enable_client_middleware(config)
          enable_server_middleware(config)
        end
      end

      def enable_server_middleware(config)
        server_mw_enabled = false
        config.server_middleware do |chain|
          chain.add(Middleware::RequestStore)
          chain.add(Middleware::RequestId)
          chain.add(Middleware::StoreRequestDetails)
          chain.add(Middleware::RequestLogger)
          server_mw_enabled = true
        end
        server_mw_enabled # Shoryuken configuration may skip that block in non-worker setups
      end

      def enable_client_middleware(config)
        config.client_middleware do |chain|
          chain.add(Middleware::MessageTracer)
        end
      end

      def suffix_tree_path(config, tag)
        config.server_middleware do |chain|
          chain.insert_after(Middleware::RequestId, Middleware::TreePathSuffix, tag)
        end
      end
    end
  end
end
