# frozen_string_literal: true

require "spec_helper"

describe Kiev::ParamFilter do
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

    it "does not filter symbol param" do
      expect(described_class.filter({ "password": "password" }, filtered, ignored)).to eq("password": "password")
    end

    it "ignores param" do
      expect(described_class.filter({ "utf8" => "utf8" }, filtered, ignored)).to eq({})
    end

    it "ignores nested param" do
      expect(described_class.filter({ "form" => { "action" => "submit" } }, filtered, ignored)).to eq("form" => {})
    end

    it "does not ignore symbol param" do
      expect(described_class.filter({ "utf8": "utf8" }, filtered, ignored)).to eq("utf8": "utf8")
    end
  end
end
