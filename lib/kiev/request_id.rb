# frozen_string_literal: true

module Kiev
  module RequestId
    module Mixin
      NEW_LINE = "\n"

      def wrap_request_id(context_reader, &_block)
        request_store = Kiev::RequestStore.store
        request_store[:request_id] = context_reader.request_id
        request_store[:request_depth] = context_reader.request_depth
        request_store[:tree_path] = context_reader.tree_path
        yield
      end
    end
  end
end
