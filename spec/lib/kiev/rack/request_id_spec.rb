# frozen_string_literal: true

require "spec_helper"

if defined?(Rack)
  describe Kiev::Rack::RequestId do
    include Rack::Test::Methods
    let(:app) { described_class.new(proc { [200, {}, ["Hello, world."]] }) }
    before { ::RequestStore.clear! }

    describe "X-Request-Id" do
      subject { get("/") }

      context "when there is no X-Request-Id" do
        before { allow(SecureRandom).to receive(:uuid).and_return("qwerty") }
        it do
          expect(Kiev::RequestStore.store[:request_id]).to eq(nil)
          expect(subject.headers["X-Request-Id"]).to eq("qwerty")
          expect(subject.headers["X-Tracking-Id"]).to eq("qwerty")
          expect(Kiev::RequestStore.store[:request_id]).to eq("qwerty")
          expect(Kiev::RequestStore.store[:tracking_id]).to eq("qwerty")
        end
      end

      context "when there is X-Request-Id" do
        before { header("X-Request-Id", "test") }
        it do
          expect(Kiev::RequestStore.store[:request_id]).to eq(nil)
          expect(subject.headers["X-Request-Id"]).to eq("test")
          expect(subject.headers["X-Tracking-Id"]).to eq("test")
          expect(Kiev::RequestStore.store[:request_id]).to eq("test")
          expect(Kiev::RequestStore.store[:tracking_id]).to eq("test")
        end
      end

      context "when there are both X-Request-Id and X-Tracking-Id with different values" do
        before do
          header("X-Request-Id", "req-test")
          header("X-Tracking-Id", "track-test")
        end
        it "returns and logs tracking_id as it has precedence" do
          expect(Kiev::RequestStore.store[:request_id]).to eq(nil)
          expect(Kiev::RequestStore.store[:tracking_id]).to eq(nil)
          expect(subject.headers["X-Request-Id"]).to eq("track-test")
          expect(subject.headers["X-Tracking-Id"]).to eq("track-test")
          expect(Kiev::RequestStore.store[:request_id]).to eq("track-test")
          expect(Kiev::RequestStore.store[:tracking_id]).to eq("track-test")
        end
      end

      context "when there is big X-Request-Id" do
        before { header("X-Request-Id", "a" * 300) }
        it do
          expect(Kiev::RequestStore.store[:request_id]).to eq(nil)
          expect(subject.headers["X-Request-Id"]).to eq("a" * 255)
          expect(subject.headers["X-Tracking-Id"]).to eq("a" * 255)
          expect(Kiev::RequestStore.store[:request_id]).to eq("a" * 255)
          expect(Kiev::RequestStore.store[:tracking_id]).to eq("a" * 255)
        end
      end
    end

    describe "X-Tracking-Id" do
      subject { get("/") }

      context "when there is no X-Tracking-Id" do
        before { allow(SecureRandom).to receive(:uuid).and_return("qwerty") }
        it do
          expect(Kiev::RequestStore.store[:request_id]).to eq(nil)
          expect(Kiev::RequestStore.store[:tracking_id]).to eq(nil)
          expect(subject.headers["X-Request-Id"]).to eq("qwerty")
          expect(subject.headers["X-Tracking-Id"]).to eq("qwerty")
          expect(Kiev::RequestStore.store[:request_id]).to eq("qwerty")
          expect(Kiev::RequestStore.store[:tracking_id]).to eq("qwerty")
        end
      end

      context "when there is X-Tracking-Id" do
        before { header("X-Tracking-Id", "test") }
        it do
          expect(Kiev::RequestStore.store[:request_id]).to eq(nil)
          expect(Kiev::RequestStore.store[:tracking_id]).to eq(nil)
          expect(subject.headers["X-Request-Id"]).to eq("test")
          expect(subject.headers["X-Tracking-Id"]).to eq("test")
          expect(Kiev::RequestStore.store[:tracking_id]).to eq("test")
          expect(Kiev::RequestStore.store[:request_id]).to eq("test")
        end
      end

      context "when there is big X-Tracking-Id" do
        before { header("X-Tracking-Id", "a" * 300) }
        it do
          expect(Kiev::RequestStore.store[:request_id]).to eq(nil)
          expect(subject.headers["X-Tracking-Id"]).to eq("a" * 255)
          expect(Kiev::RequestStore.store[:request_id]).to eq("a" * 255)
        end
      end
    end
  end
end
