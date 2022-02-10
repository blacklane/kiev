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

    it "accepts data as string" do
      Kiev.event(:test_one, "hello")
      expect(log_first["message"]).to eq("hello")
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

    describe "event with predefined severity" do
      shared_examples "with log severity" do |severity|
        it "has log severity" do
          initial = described_class.log_level
          described_class.configure do |c|
            c.log_level = ::Logger::DEBUG
          end

          Kiev.public_send(severity, :test_one)
          expect(log_first["level"]).to eq(severity.to_s.upcase)

          described_class.configure do |c|
            c.log_level = initial
          end
        end
      end

      context "with debug severity" do
        include_examples "with log severity", :debug
      end

      context "with info severity" do
        include_examples "with log severity", :info
      end

      context "with warn severity" do
        include_examples "with log severity", :warn
      end

      context "with error severity" do
        include_examples "with log severity", :error
      end

      context "with fatal severity" do
        include_examples "with log severity", :fatal
      end
    end

    describe "log data filtering" do
      it "filters params by default" do
        Kiev.event(:test_one, { credit_card_number: "123" })
        expect(log_first["credit_card_number"]).to eq("[FILTERED]")
      end

      context "when diabled for particular log level" do
        it "doesn't filters params" do
          initial = described_class.enable_filter_for_log_levels
          described_class.configure do |c|
            c.enable_filter_for_log_levels = [0, 2, 3, 4]
          end

          Kiev.event(:test_one, { credit_card_number: "123" })
          expect(log_first["credit_card_number"]).to eq("123")

          described_class.configure do |c|
            c.enable_filter_for_log_levels = initial
          end
        end
      end
    end
  end
end
