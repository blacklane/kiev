# frozen_string_literal: true

require_relative "helper"

if defined?(Sinatra)
  class SinatraIntegrationTest < MiniTest::Test
    include Rack::Test::Methods
    include LogHelper

    def app
      TestApp
    end

    def test_simple_get
      get("/")
      assert_equal("GET", log_first["verb"])
      assert_equal("/", log_first["path"])
      assert_equal(200, log_first["status"])
      assert_equal("example.org", log_first["host"])
      assert_equal("request_finished", log_first["log_name"])
      assert_equal("INFO", log_first["level"])
      assert_equal("127.0.0.1", log_first["ip"])
      assert_equal("GET /", log_first["route"])
      assert_equal(true, log_first["tree_leaf"])
      assert_equal("A", log_first["tree_path"])
      refute_empty(log_first["timestamp"])
      refute_empty(log_first["request_id"])
      refute_nil(log_first["request_duration"])
    end

    def test_x_request_id
      post(
        "/",
        "",
        "HTTP_X_REQUEST_ID" => "external-uu-rid",
        "HTTP_X_REQUEST_DEPTH" => "0",
        "HTTP_X_TREE_PATH" => "AA"
      )
      assert_equal("external-uu-rid", log_first["request_id"])
      assert_equal("AA", log_first["tree_path"])
      assert_equal(1, log_first["request_depth"])
    end

    def test_special_field
      post("/", "", "HTTP_SPECIAL_FIELD" => "special")
      assert_equal("special", log_first["special_field"])
    end

    def test_get_with_params
      get("/", some_data: "abc", password: "secret", utf8: "1")
      assert_equal("{\"some_data\":\"abc\",\"password\":\"[FILTERED]\"}", log_first["params"])
    end

    def test_post_with_params
      file = Rack::Test::UploadedFile.new("#{DATA_FOLDER}/test.txt", "image/jpeg")
      post("/post_file", some_data: "abc", "file" => file)
      assert_equal(
        "{\"some_data\":\"abc\",\"file\":{\"filename\":\"test.txt\",\"type\":\"image/jpeg\",\"name\":\"file\"," \
        "\"head\":\"Content-Disposition: form-data; name=\\\"file\\\"; filename=\\\"test.txt\\\"\\r\\n" \
        "content-Type: image/jpeg\\r\\ncontent-Length: 3308\\r\\n\"}}",
        log_first["params"]
      )
    end

    def test_log
      get("/log_in_action")
      assert_equal("log", log_first["log_name"])
      assert_equal("INFO", log_first["level"])
      refute_empty(log_first["request_id"])
    end

    def test_data
      get("/request_data")
      assert_nil(log_first["a"])
      assert_equal("0.1e1", log_first["b"]) # WTF?
      assert_equal("c", log_first["c"])
    end

    def test_exception_handled
      response = get("/raise_exception_handled")
      assert_match("internal server error", response.body)
      assert_equal(response.headers["X-Request-Id"], log_first["request_id"])
      assert_match(/RuntimeError/, log_first["error_class"])
      assert_match(/Error/, log_first["error_message"])
      refute_empty(log_first["error_backtrace"])
      refute_empty(log_first["request_id"])
      assert_equal("request_finished", log_first["log_name"])
      assert_equal("ERROR", log_first["level"])
      assert_equal(502, log_first["status"])
    end

    def test_exception_unhandled
      response = get("/raise_exception_unhandled")
      assert_match("<h1>Internal Server Error</h1>", response.body)
      assert_equal(response.headers["X-Request-Id"], log_first["request_id"])
      assert_match(/StandardError/, log_first["error_class"])
      assert_match(/Error/, log_first["error_message"])
      refute_empty(log_first["error_backtrace"])
      refute_empty(log_first["request_id"])
      assert_equal("request_finished", log_first["log_name"])
      assert_equal("ERROR", log_first["level"])
      assert_equal(500, log_first["status"])
    end

    def test_cexception_as_control_flow
      response = get("/exception_as_control_flow")
      assert_match("exception message", response.body)
      assert_equal(response.headers["X-Request-Id"], log_first["request_id"])
      assert_nil(log_first["error_class"])
      assert_nil(log_first["error_message"])
      assert_nil(log_first["error_backtrace"])
      refute_empty(log_first["request_id"])
      assert_equal("request_finished", log_first["log_name"])
      assert_equal("ERROR", log_first["level"])
      assert_equal(403, log_first["status"])
    end

    def test_json_post
      data = "{\"some_data\": \"abc\", \"password\": \"secret\", \"utf8\": \"1\"}"
      post("/", data, "CONTENT_TYPE" => "application/json")
      assert_equal("{\"some_data\":\"abc\",\"password\":\"[FILTERED]\"}", log_first["params"])
    end

    def test_json_post_body
      data = "{\"some_data\": \"abc\", \"password\": \"secret\", \"utf8\": \"1\"}"
      post("/", data, "CONTENT_TYPE" => "text/json")
      assert_equal("{\"some_data\":\"abc\",\"password\":\"[FILTERED]\"}", log_first["request_body"])
    end

    def test_malformed_json_post
      data = "{\"some_data\": \"abc\", \"password\": \"secret\", \"utf8\": \"1}"
      post("/", data, "CONTENT_TYPE" => "application/json")
      assert_nil(log_first["params"])
      assert_equal(400, last_response.status)
    end

    def test_malformed_json_post_log
      post("/", "{\"some_data\": \"abc\", \"password\": \"secret\", \"utf8\": \"1}", "CONTENT_TYPE" => "text/json")
      assert_nil(log_first["params"])
      assert_equal("{\"some_data\": \"abc\", \"password\": \"secret\", \"utf8\": \"1}", log_first["request_body"])
    end

    def test_xml_post
      post("/", "<xml><a>b</a><password>c</password><utf8>1</utf8></xml>", "CONTENT_TYPE" => "application/xml")
      assert_equal("{\"a\":[\"b\"],\"password\":\"[FILTERED]\"}", log_first["params"])
    end

    def test_malformed_xml_post_body
      post("/", "<xml><a>b</a><password>c</password><utf8>1</utf8>", "CONTENT_TYPE" => "application/xml")
      assert_nil(log_first["params"])
      assert_equal(400, last_response.status)
    end

    def test_malformed_xml_post_content_type
      post("/", "<xml><a d=d>b</a></xml>", "CONTENT_TYPE" => nil)
      # This happens due to wrong CONTENT_TYPE
      # This case is not handled by Kiev gem, instead it should be handled by application:
      # - reject all requests without CONTENT_TYPE
      # - treat all requests as CONTENT_TYPE=application/xml
      expected = "{\"\\u003cxml\\u003e\\u003ca d\":\"d\\u003eb\\u003c/a\\u003e\\u003c/xml\\u003e\"}"
      assert_equal(expected, log_first["params"])
      assert_equal(200, last_response.status)
    end

    def test_xml_post_body_log
      post("/", "<xml><a>b</a><password>c</password><utf8>1</utf8></xml>", "CONTENT_TYPE" => "text/xml")
      assert_nil(log_first["params"])
      assert_equal("<xml><a>b</a><password>[FILTERED]</password><utf8>1</utf8></xml>", log_first["request_body"])
    end

    def test_route
      get("/resource/d5588e5e-8360-4214-8c81-1c60212e7e97/test")
      if Sinatra::VERSION == "2.0.0"
        assert_equal(
          "GET \\/resource\\/" \
            "(?<uuid>([a-z0-9]){8}-([a-z0-9]){4}-([a-z0-9]){4}-([a-z0-9]){4}-([a-z0-9]){12})\\/test",
          log_first["route"]
        )
      else
        assert_equal(
          "GET (?-mix:\\/resource\\/" \
            "(?<uuid>([a-z0-9]){8}-([a-z0-9]){4}-([a-z0-9]){4}-([a-z0-9]){4}-([a-z0-9]){12})\\/test)",
          log_first["route"]
        )
      end
    end

    def test_route_with_namespace
      get("/admin/resource/d5588e5e-8360-4214-8c81-1c60212e7e97/test")
      if Sinatra::VERSION == "2.0.0"
        assert_equal(
          "GET (sinatra:\"/admin\" + regular:\"\\\\/resource\\\\/" \
            "(?<uuid>([a-z0-9]){8}-([a-z0-9]){4}-([a-z0-9]){4}-([a-z0-9]){4}-([a-z0-9]){12})\\\\/test\")",
          log_first["route"]
        )
      else
        assert_equal(
          "GET (?-mix:^(?-mix:(?-mix:\\/admin)(?-mix:\\/resource\\/" \
            "(?<uuid>([a-z0-9]){8}-([a-z0-9]){4}-([a-z0-9]){4}-([a-z0-9]){4}-([a-z0-9]){12})\\/test))$)",
          log_first["route"]
        )
      end
    end

    def test_halt
      response = get("/test_halt")
      assert_equal(400, log_first["status"])
      assert_equal(response.headers["X-Request-Id"], log_first["request_id"])
      assert_equal("halt response", response.body)
      assert_nil(log_first["error_class"])
    end

    def test_custom_halt
      response = get("/test_custom_halt")
      assert_equal(401, log_first["status"])
      assert_equal(response.headers["X-Request-Id"], log_first["request_id"])
      assert_equal("custom halt", response.body)
      assert_nil(log_first["error_class"])
    end
  end

  class SinatraIntegrationTest2 < MiniTest::Test
    include Rack::Test::Methods
    include LogHelper

    def app
      TestApp2
    end

    def test_exception_handled
      response = get("/raise_exception_handled")
      assert_match("internal server error", response.body)
      assert_nil(response.headers["X-Request-Id"]) # because of enable :show_exceptions
      assert_match(/RuntimeError/, log_first["error_class"])
      assert_match(/Error/, log_first["error_message"])
      refute_empty(log_first["error_backtrace"])
      refute_empty(log_first["request_id"])
      assert_equal("request_finished", log_first["log_name"])
      assert_equal("ERROR", log_first["level"])
      assert_equal(500, log_first["status"]) # because of enable :show_exceptions
    end

    def test_exception_unhandled
      begin
        get("/raise_exception_unhandled")
      rescue
        # because of enable :raise_errors
      end
      assert_match(/StandardError/, log_first["error_class"])
      assert_match(/Error/, log_first["error_message"])
      refute_empty(log_first["error_backtrace"])
      refute_empty(log_first["request_id"])
      assert_equal("request_finished", log_first["log_name"])
      assert_equal("ERROR", log_first["level"])
      assert_equal(500, log_first["status"])
    end
  end
end
