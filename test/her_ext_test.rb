# frozen_string_literal: true

require_relative "helper"

class HerExtTest < Minitest::Test
  if defined?(Faraday)
    def conn
      Faraday::Connection.new("http://example.net/") do |builder|
        builder.use Kiev::HerExt::ClientRequestId
        builder.adapter(:test) do |stub|
          stub.get("/") do |env|
            [200, {}, env[:request_headers]["X-Request-Id"]]
          end
        end
      end
    end

    def test_middleware_adds_request_id
      Kiev::RequestStore.store[:request_id] = "test"
      response = conn.get("/")
      assert_equal("test", response.body)
    end
  end

  if defined?(Her)
    Her::API.setup(url: "https://api.example.com") do |builder|
      # Request
      builder.use Kiev::HerExt::ClientRequestId
      # Response
      builder.use Her::Middleware::DefaultParseJSON
      # Stub connection
      builder.adapter(:test) do |stub|
        stub.get("/users/1") do |env|
          [200, {}, { name: env[:request_headers]["X-Request-Id"] }.to_json]
        end
      end
    end

    class ::User
      include ::Her::Model
    end

    def test_her_passes_request_id
      Kiev::RequestStore.store[:request_id] = "test1"
      assert_equal("test1", User.find(1).name)
    end
  end
end
