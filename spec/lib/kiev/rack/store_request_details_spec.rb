# frozen_string_literal: true

require "spec_helper"

if defined?(Rack)
  describe Kiev::Rack::StoreRequestDetails do
    include Rack::Test::Methods
    let(:app) { described_class.new(proc { [200, { "HTTP_X_REQUEST_ID" => "id" }, ["Hello, world."]] }) }
    before { ::RequestStore.clear! }

    describe "RequestStore" do
      subject { get("/") }

      it "stores request_path" do
        expect(Kiev::RequestStore.store[:request_path]).to eq(nil)
        subject
        expect(Kiev::RequestStore.store[:request_path]).to eq("/")
      end

      it "stores request_verb" do
        expect(Kiev::RequestStore.store[:request_verb]).to eq(nil)
        subject
        expect(Kiev::RequestStore.store[:request_verb]).to eq("GET")
      end

      it "stores web" do
        expect(Kiev::RequestStore.store[:web]).to eq(nil)
        subject
        expect(Kiev::RequestStore.store[:web]).to eq(true)
      end
    end
  end
end
