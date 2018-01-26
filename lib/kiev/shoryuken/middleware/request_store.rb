# frozen_string_literal: true

module Kiev
  module Shoryuken
    module Middleware
      class RequestStore
        include Kiev::RequestStore::Mixin

        def call(_worker, _queue, _message, _body, &block)
          wrap_request_store(&block)
        end
      end
    end
  end
end
