# frozen_string_literal: true

module Kiev
  module Rack
    class StoreRequestDetails
      def initialize(app)
        @app = app
      end

      def call(env)
        request = ::Rack::Request.new(env)
        RequestStore.store[:web] = true
        RequestStore.store[:request_verb] = request.request_method
        RequestStore.store[:request_path] = request.path

        Config.instance.pre_rack_hook.call(env)
        @app.call(env)
      end
    end
  end
end
