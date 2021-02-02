# frozen_string_literal: true

require "spec_helper"
require "json"
require "active_support/core_ext/time"

describe Kiev::Logger do
  describe "FORMATTER" do
    before do
      Kiev.configure do |c|
        c.app = "test_app"
        c.persistent_log_fields = [:client]
      end
      ::RequestStore.clear!
    end

    after do
      Kiev.configure do |c|
        c.persistent_log_fields = []
      end
    end

    def format(opts = {})
      time = Time.new(2000, 1, 1, 0, 0, 0, "+00:00")
      event = opts.is_a?(Hash) && opts.delete(:event) || :test_event
      described_class::FORMATTER.call(
        ::Logger::Severity::INFO, time, event, opts
      )
    end

    def subject(opts = {})
      JSON.parse(format(opts))
    end

    it "sets application" do
      expect(subject["application"]).to eq("test_app")
    end

    it "sets event" do
      expect(subject["event"]).to eq("test_event")
    end

    it "sets level" do
      expect(subject["level"]).to eq(1)
    end

    it "sets timestamp" do
      expect(subject["timestamp"]).to eq("2000-01-01T00:00:00.000Z")
    end

    it "sets request_id" do
      Kiev::RequestStore.store[:request_id] = "test_id"
      expect(subject["request_id"]).to eq("test_id")
    end

    it "sets web path and verb" do
      Kiev::RequestStore.store[:web] = true
      Kiev::RequestStore.store[:request_verb] = "GET"
      Kiev::RequestStore.store[:request_path] = "/test_path"
      expect(subject["verb"]).to eq("GET")
      expect(subject["path"]).to eq("/test_path")
    end

    it "sets job name" do
      Kiev::RequestStore.store[:background_job] = true
      Kiev::RequestStore.store[:job_name] = "TestJob"
      expect(subject["job_name"]).to eq("TestJob")
    end

    it "sets payload for request_finished" do
      Kiev[:test_payload] = true
      expect(subject["test_payload"]).to eq(nil)
      expect(subject(event: :request_finished)["test_payload"]).to eq(true)
    end

    it "sets persistent_log_fields for non request_finished" do
      Kiev[:client] = "test client"
      expect(subject["client"]).to eq("test client")
    end

    it "accepts string as message" do
      expect(subject("test_message")["message"]).to eq("test_message")
    end

    it "accepts hash as message" do
      expect(subject(data: 123)["data"]).to eq(123)
    end

    it "ends with new line" do
      expect(format).to match(/\n$/)
    end

    it "doesn't fail for 2 args" do
      time = Time.new(2000, 1, 1, 0, 0, 0, "+00:00")
      subj = described_class::FORMATTER.call(::Logger::Severity::INFO, time)

      expected = "{\"application\":\"test_app\",\"event\":\"log\",\"level\":1,"\
        "\"timestamp\":\"2000-01-01T00:00:00.000Z\"}\n"
      expect(subj).to eq(expected)
    end

    it "calls #iso8601 on Time objects" do
      subj = subject(some_time_object: Time.new(2015, 1, 1, 12, 13, 14.123, "+00:00"))
      expect(subj["some_time_object"]).to eq("2015-01-01T12:13:14.122+00:00")
    end

    it "calls #iso8601 on DateTime objects" do
      skip unless defined?(DateTime)

      subj = subject(some_datetime_object: DateTime.new(2015, 1, 1, 12, 13, 14, "+00:00"))
      expect(subj["some_datetime_object"]).to eq("2015-01-01T12:13:14.000+00:00")
    end

    it "calls #iso8601 on ActiveSupport::TimeWithZone objects" do
      skip unless defined?(ActiveSupport::TimeWithZone)

      subj = subject(some_timezone_object: Time.new(2015, 1, 1, 12, 13, 14, "+00:00").in_time_zone("UTC"))
      expect(subj["some_timezone_object"]).to eq("2015-01-01T12:13:14.000Z")
    end
  end
end
