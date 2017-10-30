# frozen_string_literal: true

module Kiev
  module Rack
    class SilenceActionDispatchLogger
      class << self
        attr_accessor :disabled
      end

      NULL_LOGGER = ::Logger.new("/dev/null")

      def initialize(app)
        @app = app
      end

      def call(env)
        env["action_dispatch.logger"] = NULL_LOGGER unless self.class.disabled
        @app.call(env)
      end
    end
  end
end
