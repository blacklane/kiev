# frozen_string_literal: true

require_relative "helper"

if defined?(Rails)
  class RailsIntegrationTest < ActionDispatch::IntegrationTest
    include LogHelper

    def test_simple_get
      remote_addr = "107.110.2.17"
      get("/", {}, "REMOTE_ADDR": remote_addr)
      assert_equal("GET", log_first["verb"])
      assert_equal("/", log_first["path"])
      assert_equal(200, log_first["status"])
      assert_equal("www.example.com", log_first["host"])
      assert_equal("request_finished", log_first["event"])
      assert_equal("INFO", log_first["level"])
      assert_equal(remote_addr, log_first["ip"])
      assert_equal("root#show", log_first["route"])
      assert_equal(true, log_first["tree_leaf"])
      assert_equal("A", log_first["tree_path"])
      refute_empty(log_first["timestamp"])
      refute_empty(log_first["request_id"])
      refute_nil(log_first["request_duration"])
    end

    def test_get_with_x_forwarded_for_header
      remote_addr = "107.110.2.17"
      http_forwarded_for = "213.4.214.155"
      get("/", {}, "REMOTE_ADDR": remote_addr, "HTTP_X_FORWARDED_FOR": http_forwarded_for)
      assert_equal(http_forwarded_for, log_first["ip"])
    end

    def test_x_request_id
      get(
        "/",
        {},
        "X-Request-Id" => "external-uu-rid",
        "X-Request-Depth" => "0",
        "X-Tree-Path" => "AA"
      )
      assert_equal("external-uu-rid", log_first["request_id"])
      assert_equal("AA", log_first["tree_path"])
      assert_equal(1, log_first["request_depth"])
    end

    def test_special_field
      post("/", "", "Special-Field" => "special")
      assert_equal("special", log_first["special_field"])
    end

    def test_get_with_params
      get("/", some_data: "abc", password: "secret", utf8: "1")
      assert_equal("{\"some_data\":\"abc\",\"password\":\"[FILTERED]\"}", log_first["params"])
    end

    def test_post_with_params
      upload = Rack::Test::UploadedFile.new("#{DATA_FOLDER}/test.txt", "image/jpeg")
      post("/post_file", some_data: "abc", "file" => upload)
      assert_not_nil(log_first)
      assert_equal(
        "{\"some_data\":\"abc\",\"file\":{\"original_filename\":\"test.txt\",\"content_type\":\"image/jpeg\","\
        "\"headers\":\"Content-Disposition: form-data; name=\\\"file\\\"; filename=\\\"test.txt\\\"\\r\\n"\
        "Content-Type: image/jpeg\\r\\nContent-Length: 3308\\r\\n\"}}",
        log_first["params"]
      )
    end

    def test_log
      get("/log_in_action")
      assert_equal("log", log_first["event"])
      assert_equal("INFO", log_first["level"])
      refute_empty(log_first["request_id"])
      assert_nil(log_first["route"])
      assert_not_nil(log_last)
      assert_equal("root#log_in_action", log_last["route"])
    end

    def test_data
      get("/request_data")
      assert_nil(log_first["a"])
      assert_equal("1.0", log_first["b"])
      assert_equal("c", log_first["c"])
      assert_equal("{\"id\":100,\"name\":\"Joe\",\"money\":null}", log_first["d"])
      assert_equal(-3.14, log_first["e"])
      assert_equal(true, log_first["f"])
      assert_equal(false, log_first["j"])
    end

    def test_exception
      begin
        get("/raise_exception")
        assert_equal(500, status)
      rescue
        # in case of action_dispatch.show_exceptions = false
      end
      assert_equal("root#raise_exception", log_first["route"])
      assert_match(/RuntimeError/, log_first["error_class"])
      assert_match(/Error/, log_first["error_message"])
      refute_empty(log_first["error_backtrace"])
      refute_empty(log_first["request_id"])
      assert_equal("request_finished", log_first["event"])
      assert_equal("INFO", log_first["level"])
      assert_equal(500, log_first["status"])
    end

    if defined?(ActiveRecord)
      def test_record_not_found
        begin
          get("/record_not_found")
          assert_equal(404, status)
        rescue
          # in case of action_dispatch.show_exceptions = false
        end
        assert_equal("root#record_not_found", log_first["route"])
        assert_nil(log_first["error_class"])
        refute_empty(log_first["request_id"])
        assert_equal("request_finished", log_first["event"])
        assert_equal("INFO", log_first["level"])
        assert_equal(404, log_first["status"])
      end
    end

    def test_cexception_as_control_flow
      status = get("/exception_as_control_flow")
      assert_equal(403, status)
      assert_nil(log_first["error_class"])
      assert_nil(log_first["error_message"])
      assert_nil(log_first["error_backtrace"])
      refute_empty(log_first["request_id"])
      assert_equal("request_finished", log_first["event"])
      assert_equal("INFO", log_first["level"])
    end

    def test_json_post
      json = "{\"some_data\": \"abc\", \"password\": \"secret\", \"utf8\": \"1\"}"
      post("/", json, "CONTENT_TYPE" => "application/json")
      assert_equal("{\"some_data\":\"abc\",\"password\":\"[FILTERED]\"}", log_first["params"])
    end

    def test_malformed_json_post
      begin
        malformed_json = "{\"some_data\": \"abc\", \"password\": \"secret\", \"utf8\": "
        status = post("/", malformed_json, "CONTENT_TYPE" => "application/json")
        assert_equal(400, status)
      rescue
        # in case of action_dispatch.show_exceptions = false
      end
      assert_nil(log_first["params"])
      assert_equal(400, log_first["status"])
    end

    def test_xml_post
      post("/", "<xml><a>b</a><password>c</password><utf8>1</utf8></xml>", "CONTENT_TYPE" => "application/xml")
      assert_equal("{\"xml\":{\"a\":\"b\",\"password\":\"[FILTERED]\"}}", log_first["params"])
    end

    def test_malformed_xml_post
      begin
        status = post("/", "not xml", "CONTENT_TYPE" => "application/xml")
        assert_equal(400, status)
      rescue
        # in case of action_dispatch.show_exceptions = false
      end
      assert_nil(log_first["params"])
      assert_equal(400, log_first["status"])
    end

    def test_route
      get("/get_by_id/123")
      assert_equal("root#get_by_id", log_first["route"])
      assert_equal("/get_by_id/123", log_first["path"])
      reset_logs
      get("/get_by_id/234")
      assert_equal("root#get_by_id", log_last["route"])
      assert_equal("/get_by_id/234", log_last["path"])
      reset_logs
      post("/get_by_id/345")
      assert_equal("root#get_by_id", log_last["route"])
      assert_equal("/get_by_id/345", log_last["path"])
      reset_logs
      get("/admin/get_by_id/123")
      assert_equal("admin/root#get_by_id", log_first["route"])
      assert_equal("/admin/get_by_id/123", log_first["path"])
      reset_logs
      get("/admin/get_by_id/234")
      assert_equal("admin/root#get_by_id", log_last["route"])
      assert_equal("/admin/get_by_id/234", log_last["path"])
      reset_logs
      post("/admin/get_by_id/345")
      assert_equal("admin/root#get_by_id", log_last["route"])
      assert_equal("/admin/get_by_id/345", log_last["path"])
    end

    def test_event
      get("/test_event")
      assert_equal("{\"id\":1000,\"name\":\"Jane\",\"money\":\"0.333333333333333333\"}", log_first["some_data"])
      assert_equal("test_event", log_first["event"])
    end
  end
end
