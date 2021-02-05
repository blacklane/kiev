# frozen_string_literal: true

require "spec_helper"
require "ruby-kafka"

if defined?(::Kafka)
  describe Kiev::Kafka::ContextInjector do
    before do
      ::RequestStore.store[:subrequest_count] = 3
    end
    after do
      ::RequestStore.store[:kiev] = {}
      ::RequestStore.store.delete(:subrequest_count)
    end

    let(:kiev_store) { Kiev::RequestStore.store }

    subject { described_class.new.call }
    let(:tracking_id) { SecureRandom.uuid }
    before do
      kiev_store[:tracking_id] = tracking_id
    end

    it "injects payload context into hash argument" do
      expect(subject).to eq(
        "X-Tracking-Id" => tracking_id,
        "X-Tree-Path" => "B"
      )
    end

    context "when more context present" do
      before do
        kiev_store[:tree_path] = "FAKA"
        kiev_store[:request_id] = tracking_id
        kiev_store[:request_depth] = 3
      end

      it "returns more in headers" do
        expect(subject).to eq(
          "X-Tracking-Id" => tracking_id,
          "X-Request-Id" => tracking_id,
          "X-Request-Depth" => 3,
          "X-Tree-Path" => "FAKAB"
        )
      end
    end

    context "when jobs_propagated_fields setup" do
      before do
        default_setup = Kiev::Config.instance.all_jobs_propagated_fields
        allow(Kiev::Config.instance).to receive(:all_jobs_propagated_fields).and_return(
          default_setup + %i(some_other_field and_another)
        )
        Kiev[:some_other_field] = "foo"
        Kiev[:and_another] = "bar"
        Kiev[:skip_me] = "bar"
      end

      it "passes them" do
        expect(subject).to eq(
          "X-Tracking-Id" => tracking_id,
          "X-Tree-Path" => "B",
          "some_other_field" => "foo",
          "and_another" => "bar"
        )
      end
    end

    it "enhances argument headers variable as well" do
      some_headers = {foo: 42}
      described_class.new.call(some_headers)
      expect(some_headers).to eq(
        "X-Tracking-Id" => tracking_id,
        "X-Tree-Path" => "B",
        foo: 42
      )
    end
  end
end
