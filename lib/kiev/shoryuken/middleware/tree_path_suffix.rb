# frozen_string_literal: true

module Kiev
  module Shoryuken
    module Middleware
      class TreePathSuffix
        def initialize(tag)
          @tag = tag.dup.freeze
        end

        def call(_worker, _queue, _message, _body)
          request_store = Kiev::RequestStore.store
          request_store[:tree_path] ||= ""
          request_store[:tree_path] += @tag
          yield
        end
      end
    end
  end
end
