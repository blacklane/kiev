# frozen_string_literal: true

require "spec_helper"

describe Kiev::SubrequestHelper do
  before do
    Kiev::RequestStore.store.clear
    Kiev::RequestStore.store[:request_depth] = 0
    Kiev::RequestStore.store[:request_id] = "asdf"
    Kiev::RequestStore.store[:tree_path] = "A"
  end
  describe "root_path" do
    it { expect(described_class.root_path(synchronous: true)).to eq("A") }
    it { expect(described_class.root_path(synchronous: false)).to eq("B") }
  end
  describe "subrequest_path" do
    it { expect(described_class.subrequest_path(synchronous: true)).to eq("AA") }
    it { expect(described_class.subrequest_path(synchronous: false)).to eq("AB") }
  end
  context "consequent pathes are lexicographically sortable" do
    it do
      a = described_class.subrequest_path(synchronous: true)
      b = described_class.subrequest_path(synchronous: true)
      expect(a < b).to be(true)
    end
    it do
      a = described_class.subrequest_path(synchronous: true)
      b = described_class.subrequest_path(synchronous: false)
      expect(a < b).to be(true)
    end
    it do
      a = described_class.subrequest_path(synchronous: false)
      b = described_class.subrequest_path(synchronous: true)
      expect(a < b).to be(true)
    end
    it do
      a = described_class.subrequest_path(synchronous: false)
      b = described_class.subrequest_path(synchronous: false)
      expect(a < b).to be(true)
    end
  end
  describe "headers" do
    it do
      expect(described_class.headers).to eq(
        "X-Tree-Path" => "AA",
        "X-Request-Depth" => "0",
        "X-Request-Id" => "asdf"
      )
      expect(described_class.headers).to eq(
        "X-Tree-Path" => "AC",
        "X-Request-Depth" => "0",
        "X-Request-Id" => "asdf"
      )
    end
    it "supports metadata" do
      expect(described_class.headers(metadata: true)).to eq(
        request_depth: "0",
        request_id: "asdf",
        tree_path: "AA"
      )
      expect(described_class.headers(metadata: true)).to eq(
        request_depth: "0",
        request_id: "asdf",
        tree_path: "AC"
      )
    end
  end
  describe "payload" do
    it do
      expect(described_class.payload).to eq(
        "tree_path" => "AB",
        "request_depth" => 0,
        "request_id" => "asdf"
      )
      expect(described_class.payload).to eq(
        "tree_path" => "AD",
        "request_depth" => 0,
        "request_id" => "asdf"
      )
    end
  end
end
