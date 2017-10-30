# frozen_string_literal: true

require_relative "../base"

module Kiev
  module HerExt
    class ClientRequestId < Faraday::Middleware
      def call(env)
        env[:request_headers].merge!(SubrequestHelper.headers)
        @app.call(env)
      end
    end
  end
end
