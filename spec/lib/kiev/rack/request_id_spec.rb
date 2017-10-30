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
          expect(Kiev::RequestStore.store[:request_id]).to eq("qwerty")
        end
      end

      context "when there is X-Request-Id" do
        before { header("X-Request-Id", "test") }
        it do
          expect(Kiev::RequestStore.store[:request_id]).to eq(nil)
          expect(subject.headers["X-Request-Id"]).to eq("test")
          expect(Kiev::RequestStore.store[:request_id]).to eq("test")
        end
      end

      context "when there is big X-Request-Id" do
        before { header("X-Request-Id", "a" * 300) }
        it do
          expect(Kiev::RequestStore.store[:request_id]).to eq(nil)
          expect(subject.headers["X-Request-Id"]).to eq("a" * 255)
          expect(Kiev::RequestStore.store[:request_id]).to eq("a" * 255)
        end
      end
    end
  end
end
