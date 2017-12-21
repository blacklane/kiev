# frozen_string_literal: true

require "spec_helper"
require "ostruct"

describe Kiev::Config do
  describe "constants" do
    it do
      expect(described_class::FILTERED_PARAMS).to eq(
        %w(
          client_secret
          token
          facebook_access_token
          password
          password_confirmation
          old_password
          credit_card_number
          credit_card_cvv
          credit_card_holder
          credit_card_expiry_month
          credit_card_expiry_year
          CardNumber
          CardCVV
          CardExpires
        )
      )
    end
    it do
      expect(described_class::IGNORED_PARAMS).to eq(
        %w(
          controller
          action
          format
          authenticity_token
          utf8
          tempfile
        ) << :tempfile
      )
    end
  end

  describe "DEFAULT_LOG_REQUEST_ERROR_CONDITION" do
    let(:request) { nil }
    subject { described_class::DEFAULT_LOG_REQUEST_ERROR_CONDITION }
    context "404 status code" do
      let(:response) { OpenStruct.new(status: 404) }
      it { expect(subject.call(request, response)).to eq(false) }
    end
    context "400 status code" do
      let(:response) { OpenStruct.new(status: 400) }
      it { expect(subject.call(request, response)).to eq(true) }
    end
    context "200 status code" do
      let(:response) { OpenStruct.new(status: 200) }
      it { expect(subject.call(request, response)).to eq(true) }
    end
  end

  describe "DEFAULT_LOG_REQUEST_CONDITION" do
    let(:response) { nil }
    subject { described_class::DEFAULT_LOG_REQUEST_CONDITION }
    context "simple request" do
      let(:request) { OpenStruct.new(path: "/") }
      it { expect(subject.call(request, response)).to eq(true) }
    end
    context "health request" do
      let(:request) { OpenStruct.new(path: "/health") }
      it { expect(subject.call(request, response)).to eq(false) }
    end
    context "ping request" do
      let(:request) { OpenStruct.new(path: "/ping") }
      it { expect(subject.call(request, response)).to eq(false) }
    end
    context "/something/ping request" do
      let(:request) { OpenStruct.new(path: "/something/ping") }
      it { expect(subject.call(request, response)).to eq(true) }
    end
    context "media request" do
      let(:request) { OpenStruct.new(path: "/test.jpg") }
      it { expect(subject.call(request, response)).to eq(false) }
    end
  end

  describe "DEFAULT_LOG_RESPONSE_BODY_CONDITION" do
    let(:request) { nil }
    subject { described_class::DEFAULT_LOG_RESPONSE_BODY_CONDITION }
    context "500 status code for json response" do
      let(:response) { OpenStruct.new(status: 500, content_type: "json/something") }
      it { expect(subject.call(request, response)).to eq(false) }
    end
    context "400 status code for json response" do
      let(:response) { OpenStruct.new(status: 400, content_type: "json/something") }
      it { expect(subject.call(request, response)).to eq(true) }
    end
    context "200 status code for json response" do
      let(:response) { OpenStruct.new(status: 200, content_type: "json/something") }
      it { expect(subject.call(request, response)).to eq(false) }
    end
    context "500 status code for xml response" do
      let(:response) { OpenStruct.new(status: 500, content_type: "xml/something") }
      it { expect(subject.call(request, response)).to eq(false) }
    end
    context "400 status code for xml response" do
      let(:response) { OpenStruct.new(status: 400, content_type: "xml/something") }
      it { expect(subject.call(request, response)).to eq(true) }
    end
    context "200 status code for xml response" do
      let(:response) { OpenStruct.new(status: 200, content_type: "xml/something") }
      it { expect(subject.call(request, response)).to eq(false) }
    end
    context "400 status code for html response" do
      let(:response) { OpenStruct.new(status: 400, content_type: "html/something") }
      it { expect(subject.call(request, response)).to eq(false) }
    end
  end

  describe "DEFAULT_PRE_RACK_HOOK" do
    let(:env) { { "HTTP_FIELD" => "f" } }
    subject { described_class::DEFAULT_PRE_RACK_HOOK }
    before do
      allow_any_instance_of(described_class).to receive(:http_propagated_fields) { { field: "field" } }
      allow(Kiev::Util).to receive(:sanitize).and_call_original
      allow(Kiev::Util).to receive(:to_http).and_call_original
      allow(Kiev).to receive(:[]=)
    end
    it do
      expect(Kiev::Util).to receive(:sanitize).with("f")
      expect(Kiev::Util).to receive(:to_http).with("field")
      expect(Kiev).to receive(:[]=).with(:field, "f")
      subject.call(env)
    end
  end

  describe "http_propagated_fields" do
    subject { described_class.instance }
    before { subject.http_propagated_fields = {} }
    after { subject.http_propagated_fields = {} }
    it do
      subject.http_propagated_fields = {
        request_id: "Request-Id",
        http_field: "X-Field"
      }
      expect(subject.http_propagated_fields).to eq(http_field: "X-Field")
      expect(subject.all_http_propagated_fields).to eq(
        request_id: "Request-Id",
        request_depth: "X-Request-Depth",
        tree_path: "X-Tree-Path",
        http_field: "X-Field"
      )
    end
  end

  describe "jobs_propagated_fields" do
    subject { described_class.instance }
    before { subject.jobs_propagated_fields = [] }
    after { subject.jobs_propagated_fields = [] }
    it do
      subject.jobs_propagated_fields = [:request_id, :jobs_field]
      expect(subject.jobs_propagated_fields).to eq([:jobs_field])
      expect(subject.all_jobs_propagated_fields).to eq(
        [:request_id, :request_depth, :tree_path, :jobs_field]
      )
    end
  end
end
