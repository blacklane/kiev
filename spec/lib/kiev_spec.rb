# frozen_string_literal: true

require "spec_helper"

describe Kiev do
  include KievHelper

  describe "logger" do
    it "always returns same instance" do
      log_1 = described_class.logger
      described_class.configure do |c|
        c.log_path = "/dev/null"
      end
      log_2 = described_class.logger
      expect(log_1).to eq(log_2)
    end
  end

  describe "payload" do
    it "expects Hash as argument" do
      expect { described_class.payload("abc") }.to raise_error(ArgumentError)
    end
    it "stores all data in RequestStore" do
      described_class.payload(a: 1)
      described_class.payload(b: 2)
      expect(Kiev::RequestStore.store[:payload]).to eq(a: 1, b: 2)
    end
  end

  describe "event" do
    before do
      enable_log_tracking
      reset_logs
    end
    after do
      disable_log_tracking
    end

    it "accepts one argument" do
      Kiev.event(:test_one)
      expect(log_first["log_name"]).to eq("test_one")
    end

    it "accepts two arguments" do
      Kiev.event(:test_one, data: "hello")
      expect(log_first["data"]).to eq("hello")
    end

    context "when sensitive data" do
      let(:data) { { data: "hello" } }

      before { allow(Kiev::ParamFilter).to receive(:filter) }

      it "filters logging data" do
        Kiev.event(:test_one, data)
        expect(Kiev::ParamFilter).to have_received(:filter)
          .with(data, Kiev::Config.instance.filtered_params, Kiev::Config.instance.ignored_params)
      end
    end
  end
end
