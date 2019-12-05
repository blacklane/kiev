# frozen_string_literal: true

require_relative "rack/request_logger"
require_relative "rack/store_request_details"
require_relative "rack/request_id"

module Kiev
  module Hanami
    def self.included(base)
      base.configure do
        # The order is important
        middleware.use(::RequestStore::Middleware)
        middleware.use(Kiev::Rack::RequestLogger)
        middleware.use(Kiev::Rack::StoreRequestDetails)
        middleware.use(Kiev::Rack::RequestId)
      end
    end
  end
end
