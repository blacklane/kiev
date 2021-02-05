# frozen_string_literal: true

require "spec_helper"
require "ruby-kafka"

if defined?(::Kafka)
  describe Kiev::Kafka::ContextExtractor do
    after do
      ::RequestStore.store[:kiev] = {}
      ::RequestStore.store.delete(:subrequest_count)
    end
    context 'when message has context' do
      let(:tracking_id) { SecureRandom.uuid }

      subject { described_class.new.call(message) }
      let(:headers) do
        {
          "X-Tracking-Id" => tracking_id,
          "X-Tree-Path" =>"KAFKA",
          "X-Request-Depth" => "4"
        }
      end
      let(:message) do
        Kafka::FetchedMessage.new(message: Kafka::Protocol::Record.new(key: "msg_key", value: "", headers: headers), topic: "", partition: 0)
      end
      it "extracts basic fields" do
        subject
        expect(Kiev.request_id).to eq(tracking_id)
        expect(Kiev::RequestStore.store[:tree_path]).to eq("KAFKA")
        expect(Kiev::RequestStore.store[:request_depth]).to eq(5)
        expect(Kiev::RequestStore.store.dig(:payload, :message_key)).to eq("msg_key")
      end

      context "for headers in plain format (no X- and uppercase)" do
        let(:headers) do
          {
            "tracking_id" => tracking_id,
            "tree_path" =>"KAFkA",
            "request_depth" => "3"
          }
        end

        it "extracts them as well" do
          subject
          expect(Kiev.request_id).to eq(tracking_id)
          expect(Kiev::RequestStore.store[:tree_path]).to eq("KAFkA")
          expect(Kiev::RequestStore.store[:request_depth]).to eq(4)
          expect(Kiev::RequestStore.store.dig(:payload, :message_key)).to eq("msg_key")
        end
      end

      context "extra fields if job-propagated are also stored in payload context" do
        let(:headers) do
          {
            "other_uuid" => tracking_id,
            "skip_me" =>"not tracked",
            "X-Accept-This" => "3"
          }
        end

        it "extracts them as well" do
          allow(Kiev::Config.instance).to receive(:jobs_propagated_fields).and_return(%i(other_uuid accept_this))
          subject
          payload_context = Kiev::RequestStore.store[:payload]
          expect(payload_context[:other_uuid]).to eq(tracking_id)
          expect(payload_context[:accept_this]).to eq("3")
          expect(payload_context[:skip_me]).to be_nil
        end
      end
    end
  end
end
