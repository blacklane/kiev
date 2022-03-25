# frozen_string_literal: true

require "spec_helper"
require "rack"

describe Kiev::RequestBodyFilter do
  describe ".filter" do
    let(:request) do
      Rack::Request.new(
        Rack::MockRequest.env_for(
          "/",
          "REQUEST_METHOD" => "POST",
          "CONTENT_TYPE" => "application/json",
          :input => "{\"password\":12345}"
        )
      )
    end

    it "doesn't filter" do
      initial = Kiev.config.disable_filter_for_log_levels
      Kiev.config.disable_filter_for_log_levels = [::Logger::INFO]
      result = described_class.filter(
        "application/json",
        request.body,
        ["password"],
        []
      )
      expect(result).to eq("{\"password\":12345}")
      Kiev.config.disable_filter_for_log_levels = initial
    end

    it "filters by default" do
      result = described_class.filter(
        "application/json",
        request.body,
        ["password"],
        []
      )
      expect(result).to eq("password" => "[FILTERED]")
    end
  end
end
