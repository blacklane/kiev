# frozen_string_literal: true

require "securerandom"

module Kiev
  module Sidekiq
    class RequestId
      REQUEST_ID = "request_id"
      REQUEST_DEPTH = "request_depth"
      TREE_PATH = "tree_path"

      def call(_worker, job, _queue)
        Kiev::RequestStore.store[:request_id] = request_id(job)
        Kiev::RequestStore.store[:request_depth] = request_depth(job)
        Kiev::RequestStore.store[:tree_path] = tree_path(job)
        yield
      end

      private

      def request_id(job)
        # cron jobs will be triggered without request_id
        job[REQUEST_ID] || SecureRandom.uuid
      end

      def tree_root?(job)
        !job[REQUEST_ID]
      end

      def request_depth(job)
        tree_root?(job) ? 0 : (job[REQUEST_DEPTH].to_i + 1)
      end

      def tree_path(job)
        tree_root?(job) ? SubrequestHelper.root_path(synchronous: false) : job[TREE_PATH]
      end
    end
  end
end
