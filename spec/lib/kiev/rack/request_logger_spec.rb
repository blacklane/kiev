# frozen_string_literal: true

require "spec_helper"

if defined?(Rack)
  describe Kiev::Rack::RequestLogger do
    include Rack::Test::Methods
    before do
      allow(Kiev).to receive(:event)
      allow(Time).to receive(:now).and_return(Time.new(2000))
    end

    let(:rack_app) { proc { [200, {}, ["body"]] } }
    let(:app) { described_class.new(rack_app) }
    let(:logger) { Kiev::Config.instance.logger }
    subject do
      get("/")
      Kiev
    end

    def request_finished(options = {})
      [:request_finished, {
        host: "example.org",
        params: nil,
        ip: "127.0.0.1",
        user_agent: nil,
        status: 200,
        request_duration: 0.0,
        route: nil
      }.merge(options)]
    end

    context "200 response" do
      it "logs request" do
        expect(subject).to have_received(:event).with(*request_finished)
      end

      it "sets user_agent" do
        header("User-Agent", "Mozilla")
        expect(subject).to have_received(:event).with(*request_finished(user_agent: "Mozilla"))
      end

      context "other requests" do
        subject { Kiev }

        it "sets params" do
          get("/", test: "123")
          expect(subject).to have_received(:event).with(*request_finished(params: { "test" => "123" }))
        end

        it "filters params" do
          get("/", password: "secret")
          expect(subject).to have_received(:event).with(*request_finished(params: { "password" => "[FILTERED]" }))
        end

        it "ignores params" do
          get("/", utf8: "1")
          expect(subject).to have_received(:event).with(*request_finished)
        end

        it "ignores request body" do
          post("/", "{\"password\":\"secret\"}", "CONTENT_TYPE" => "application/json")
          expect(subject).to have_received(:event).with(*request_finished)
        end
      end
    end

    context "401 response" do
      context "html" do
        let(:rack_app) { proc { [401, { "Content-Type" => "text/html" }, "body"] } }
        it "does not log body" do
          expect(subject).to have_received(:event).with(*request_finished(status: 401))
        end
      end

      context "json" do
        let(:rack_app) { proc { [401, { "Content-Type" => "application/json" }, ["{\"secret\":\"not filtered\"}"]] } }
        it "logs body" do
          expect(subject).to have_received(:event)
            .with(*request_finished(status: 401, body: "{\"secret\":\"not filtered\"}"))
        end
      end

      context "xml" do
        let(:rack_app) do
          proc { [401, { "Content-Type" => "text/xml" }, ["<xml><secret>not filtered</secret></xml>"]] }
        end
        it "logs body" do
          expect(subject).to have_received(:event)
            .with(*request_finished(status: 401, body: "<xml><secret>not filtered</secret></xml>"))
        end
      end
    end

    context "404 response" do
      context "html" do
        let(:rack_app) { proc { [404, { "Content-Type": "text/html" }, "body"] } }
        it "does not log body" do
          expect(subject).to have_received(:event)
            .with(*request_finished(status: 404))
        end
      end

      context "json" do
        let(:payload) { %({ "a": 1 }) }
        let(:rack_app) { proc { [404, { "Content-Type" => "application/json" }, [payload]] } }
        it "logs body" do
          expect(subject).to have_received(:event)
            .with(*request_finished(status: 404, body: payload))
        end
      end
    end
  end
end
