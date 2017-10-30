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
        request_id_header_in = to_http(:request_id)

        request_id = make_request_id(env[RAILS_REQUEST_ID] || env[request_id_header_in])
        RequestStore.store[:request_id] = request_id
        RequestStore.store[:request_depth] = request_depth(env)
        RequestStore.store[:tree_path] = tree_path(env)

        @app.call(env).tap { |_status, headers, _body| headers[request_id_header_out] = request_id }
      end

      private

      # TODO: in Rails 5 they set `headers[X_REQUEST_ID]`, so this will not work
      # https://github.com/rails/rails/blob/master/actionpack/lib/action_dispatch/middleware/request_id.rb
      # https://github.com/interagent/pliny/blob/master/lib/pliny/middleware/request_id.rb
      def tree_root?(env)
        request_id_header_in = to_http(:request_id)
        !env[request_id_header_in]
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

      def make_request_id(request_id)
        if request_id.nil? || request_id.empty?
          internal_request_id
        else
          Util.sanitize(request_id)
        end
      end

      def internal_request_id
        SecureRandom.uuid
      end
    end
  end
end
