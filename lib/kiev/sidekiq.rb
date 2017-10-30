# frozen_string_literal: true

require_relative "base"

module Kiev
  module Sidekiq
    require_relative "sidekiq/client_request_id"
    require_relative "sidekiq/request_store"
    require_relative "sidekiq/request_logger"
    require_relative "sidekiq/request_id"
    require_relative "sidekiq/store_request_details"

    class << self
      def enable(base = nil)
        base ||= ::Sidekiq
        base.configure_client do |config|
          enable_client_middleware(config)
        end
        base.configure_server do |config|
          enable_client_middleware(config)
          enable_server_middleware(config)
        end
      end

      def enable_server_middleware(config)
        config.server_middleware do |chain|
          chain.prepend(Kiev::Sidekiq::RequestLogger)
          chain.prepend(Kiev::Sidekiq::StoreRequestDetails)
          chain.prepend(Kiev::Sidekiq::RequestId)
          chain.prepend(Kiev::Sidekiq::RequestStore)
        end
      end

      def enable_client_middleware(config)
        config.client_middleware do |chain|
          chain.prepend(Kiev::Sidekiq::ClientRequestId)
        end
      end
    end
  end
end
