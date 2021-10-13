# frozen_string_literal: true

require "spec_helper"

describe Kiev::ParamFilter do
  describe "filterable" do
    subject(:filterable?) { described_class.filterable?(params) }

    context "when params is a string" do
      let(:params) { "non filterable string, yet" }

      it { is_expected.to eq(false) }
    end

    context "when params are a Hash" do
      let(:params) { { "filterable" => "params" } }

      it { is_expected.to eq(true) }
    end
  end

  describe "filter" do
    let(:filtered) { Kiev::Config.instance.filtered_params }
    let(:ignored) { Kiev::Config.instance.ignored_params }

    it "filters param" do
      expect(described_class.filter({ "password" => "password" }, filtered, ignored)).to eq("password" => "[FILTERED]")
    end

    it "filters nested param" do
      expected = { "u" => { "password" => "[FILTERED]" } }
      expect(described_class.filter({ "u" => { "password" => "password" } }, filtered, ignored)).to eq(expected)
    end

    it "filters only leafs" do
      input = { "token" => { "token" => "token", "type" => "type" } }
      expected = { "token" => { "token" => "[FILTERED]", "type" => "type" } }
      expect(described_class.filter(input, filtered, ignored)).to eq(expected)
    end

    it "filters symbol param" do
      expect(described_class.filter({ "password": "password" }, filtered, ignored)).to eq("password": "[FILTERED]")
    end

    it "filters mixed param" do
      expect(described_class.filter({ "password": "password", "password" => "password" }, filtered, ignored))
        .to eq("password": "[FILTERED]", "password" => "[FILTERED]")
    end

    it "ignores param" do
      expect(described_class.filter({ "utf8" => "utf8" }, filtered, ignored)).to eq({})
    end

    it "ignores nested param" do
      expect(described_class.filter({ "form" => { "action" => "submit" } }, filtered, ignored)).to eq("form" => {})
    end

    it "ignores symbol param" do
      expect(described_class.filter({ "utf8": "utf8" }, filtered, ignored)).to eq({})
    end

    it "ignores mixed params" do
      expect(described_class.filter({ "utf8": "utf8", "utf8" => "utf8" }, filtered, ignored)).to eq({})
    end

    context "when configuration params specified as strings and symbols at the same time" do
      context "when filtered" do
        let(:filtered) { [:password, "type"] }

        it "filters both" do
          expect(described_class.filter({ type: "type", "password" => "password"}, filtered, ignored))
            .to eq(type: "[FILTERED]", "password" => "[FILTERED]")
        end
      end

      context "when ignored" do
        let(:ignored) { [:password, "type"] }

        it "ignores both" do
          expect(described_class.filter({ type: "type", "password" => "password"}, filtered, ignored)).to eq({})
        end
      end
    end
  end
end
