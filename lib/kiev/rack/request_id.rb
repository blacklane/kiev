# frozen_string_literal: true

require "securerandom"

module Kiev
  module Rack
    class RequestId
      # for Rails 4
      RAILS_REQUEST_ID = "action_dispatch.request_id"

      def initialize(app)
        @app = app
      end

      def call(env)
        request_id_header_out = to_rack(:request_id)
        tracking_id_header_out = to_rack(:tracking_id)

        tracking_id = make_tracking_id(env[to_http(:tracking_id)] || env[RAILS_REQUEST_ID] || env[to_http(:request_id)])
        RequestStore.store[:tracking_id] = tracking_id
        RequestStore.store[:request_id] = tracking_id
        RequestStore.store[:request_depth] = request_depth(env)
        RequestStore.store[:tree_path] = tree_path(env)

        @app.call(env).tap do |_status, headers, _body|
          headers[tracking_id_header_out] = tracking_id
          headers[request_id_header_out] = tracking_id
        end
      end

      private

      def tree_root?(env)
        tracking_id_header_in = to_http(:tracking_id)
        !env[tracking_id_header_in]
      end

      def request_depth(env)
        request_depth_header = to_http(:request_depth)
        tree_root?(env) ? 0 : (env[request_depth_header].to_i + 1)
      end

      def tree_path(env)
        tree_path_header = to_http(:tree_path)
        tree_root?(env) ? SubrequestHelper.root_path(synchronous: true) : Util.sanitize(env[tree_path_header])
      end

      def to_http(value)
        Util.to_http(to_rack(value))
      end

      def to_rack(value)
        Config.instance.all_http_propagated_fields[value]
      end

      def make_tracking_id(tracking_id)
        if tracking_id.nil? || tracking_id.empty?
          internal_tracking_id
        else
          Util.sanitize(tracking_id)
        end
      end

      def internal_tracking_id
        SecureRandom.uuid
      end
    end
  end
end
