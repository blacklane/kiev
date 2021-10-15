# frozen_string_literal: true

require "spec_helper"
require "kiev/test"

if defined?(::Shoryuken)
  RSpec.describe Kiev::Shoryuken do
    # {
    #   message_id: "437eb14c-7a98-457c-a431-01671564237e",
    #   body: "test",
    #   message_attributes: message_attributes,
    #   delete: nil
    # }
    # {
    #   "request_id"    => "acc6acfe-525e-49a6-a12b-ce3f07564620",
    #   "request_depth" => 1,
    #   "tree_path"     => "B"
    # }

    before(:all) do
      # Shoryuken skips configure_server blocks unless it's running in a worker
      # process. "worker process"ness is defined only by existence of this module.
      # In Shoryuken itself it's only defined in `bin` and only gets created when
      # using `shoryuken` executable. It's not (readily) available for requiring.
      module Shoryuken::CLI
      end

      Shoryuken.logger.level = Logger::FATAL
      Kiev::Shoryuken.enable
      Kiev::Test::Log.configure
    end

    describe "client middleware when sending a message" do
      include Kiev::RequestStore::Mixin

      let(:credentials) { Aws::Credentials.new("access_key_id", "secret_access_key") }
      let(:sqs) { Aws::SQS::Client.new(stub_responses: true, credentials: credentials) }
      let(:queue_name) { "default" }
      let(:queue_url) { "https://sqs.eu-west-1.amazonaws.com:6059/0123456789/#{queue_name}" }

      let(:queue) { Shoryuken::Queue.new(sqs, queue_name) }
      before do
        allow(queue).to receive(:url).and_return(queue_url)
        allow(sqs).to receive(:send_message)
      end

      around(:each) do |example|
        wrap_request_store { example.run }
      end

      let(:message_attributes) { {} }
      let(:formatted_attributes) do
        next unless message_attributes
        message_attributes.each_with_object({}) do |(k, v), attrs|
          attrs[k.to_s] = { data_type: "String", string_value: v }
        end
      end

      def send_message
        message = { message_body: '{"a": 42}' }
        if message_attributes
          message[:message_attributes] = formatted_attributes
        end
        queue.send_message(message)
      end

      context "without anything in Kiev store" do
        before { send_message }

        it "tags it with tree_path B (first request, asynchronous)" do
          expect(sqs)
            .to have_received(:send_message)
            .with(hash_including(message_attributes: { "tree_path" => { data_type: "String", string_value: "B" } }))
        end
      end

      context "with a specified request_id in Kiev store" do
        let(:request_id) { "acc6acfe-525e-49a6-a12b-ce3f07564620" }

        before do
          Kiev::RequestStore.store[:request_id] = request_id
          Kiev::RequestStore.store[:tracking_id] = request_id
        end

        it "preserves request_id" do
          expect(sqs)
            .to receive(:send_message)
            .with(
              hash_including(
                message_attributes: hash_including(
                  "tracking_id" => { data_type: "String", string_value: request_id },
                  "request_id" => { data_type: "String", string_value: request_id }
                )
              )
            )
          send_message
        end
      end

      context "with a specified tree_path in Kiev store" do
        let(:source_tree_path) { "DAaaAAaAAAAAaaAAaaA" }

        before do
          Kiev::RequestStore.store[:tree_path] = source_tree_path
        end

        it "appends B to tree_path" do
          expect(sqs)
            .to receive(:send_message)
            .with(
              hash_including(
                message_attributes: hash_including(
                  "tree_path" => { data_type: "String", string_value: (source_tree_path + "B") }
                )
              )
            )
          send_message
        end
      end

      context "with a specified request depth in Kiev store" do
        let(:request_depth) { 5 }

        before do
          Kiev::RequestStore.store[:request_depth] = request_depth
        end

        it "preserves it as a string" do
          expect(sqs)
            .to receive(:send_message)
            .with(
              hash_including(
                message_attributes: hash_including(
                  "request_depth" => { data_type: "String", string_value: request_depth.to_s }
                )
              )
            )
          send_message
        end
      end
    end

    describe "server middleware" do
      context "when receiving a message" do
        let(:queue)     { "default" }
        let(:sqs_queue) { double(Shoryuken::Queue, visibility_timeout: 30) }

        let(:processor) { Shoryuken::Processor.new(queue, sqs_msg) }

        let(:message_body) { "test" }
        let(:message_attributes) { {} }

        let(:formatted_attributes) do
          message_attributes.each_with_object({}) do |(k, v), attrs|
            attrs[k.to_s] = double(
              Aws::SQS::Types::MessageAttributeValue,
              data_type: "String",
              string_value: v
            )
          end
        end

        def sqs_msg_from(**attrs)
          double(
            Shoryuken::Message,
            message_id: SecureRandom.uuid,
            receipt_handle: SecureRandom.uuid,
            **attrs
          )
        end

        let(:sqs_msg_attrs) do
          {
            queue_url: queue,
            body: message_body,
            message_attributes: formatted_attributes
          }
        end

        let(:sqs_msg) { sqs_msg_from(sqs_msg_attrs) }

        before do
          class TestWorker
            include Shoryuken::Worker
            shoryuken_options queue: "default"

            def perform(_sqs_msg, _body)
              true
            end
          end

          allow(Shoryuken::Client).to receive(:queues).with(queue).and_return(sqs_queue)
        end

        before  { Kiev::Test::Log.clear }

        context "without message attributes" do
          it { expect { processor.process }.to_not raise_error }

          describe "logged entry" do
            subject { Kiev::Test::Log.entries.first }

            before { processor.process }

            it { is_expected.to be_a(Hash) }

            it "has fields of a successful job" do
              is_expected.to include(
                "log_name" => "job_finished",
                "level" => "INFO",
                "body" => message_body,
                "tree_leaf" => true,
                "tree_path" => "B",
                "request_depth" => 0,
                "timestamp" => a_string_matching(/.+/),
                "request_id" => a_string_matching(/.+/),
                "tracking_id" => a_string_matching(/.+/),
                "request_duration" => (a_value > 0)
              )
            end

            it "has no error fields" do
              is_expected.to_not include(
                "error_class",
                "error_message",
                "error_backtrace"
              )
            end

            it "does not populate the store with a new request_id" do
              expect(Kiev::RequestStore.store).to_not have_key(:request_id)
            end

            context "when two messages are sent" do
              let(:other_sqs_msg) { sqs_msg_from(sqs_msg_attrs) }
              let(:other_processor) { Shoryuken::Processor.new(queue, other_sqs_msg) }
              before { other_processor.process }

              it "generates different request_ids" do
                first, second = Kiev::Test::Log.entries
                expect(first["request_id"]).to_not eq(second["request_id"])
                expect(first["tracking_id"]).to_not eq(second["tracking_id"])
              end
            end
          end
        end

        context "with message attributes" do
          let(:request_id) { "acc6acfe-525e-49a6-a12b-ce3f07564620" }
          let(:tree_path) { "AWYeAH" }
          let(:request_depth) { tree_path.length }

          let(:message_attributes) do
            {
              request_id: request_id,
              tracking_id: request_id,
              tree_path: tree_path,
              request_depth: request_depth
            }
          end

          describe "logged_entry" do
            before { processor.process }
            subject { Kiev::Test::Log.entries.first }
            it "processes tracing fields properly" do
              is_expected.to include(
                "request_id" => request_id,
                "tracking_id" => request_id,
                "tree_path" => tree_path,
                "request_depth" => (request_depth + 1)
              )
            end
          end
        end

        describe "failing worker" do
          let(:queue) { "error" }

          before do
            class UnexpectedFailure < StandardError; end

            class FailingWorker
              include Shoryuken::Worker
              shoryuken_options queue: "error"

              def perform(_sqs_msg, _body)
                raise UnexpectedFailure, "error message"
              end
            end

            allow(Shoryuken::Client)
              .to receive(:queues)
              .with(queue)
              .and_return(sqs_queue)
          end

          it "doesn't rescue the exception" do
            expect { processor.process }.to raise_error(UnexpectedFailure)
          end

          describe "logged entry" do
            subject { Kiev::Test::Log.entries.first }

            before do
              begin
                processor.process
              rescue UnexpectedFailure
              end
            end

            it "describes the error" do
              is_expected.to include(
                "error_class" => UnexpectedFailure.to_s,
                "error_message" => "error message",
                "error_backtrace" => an_instance_of(String)
              )
            end
          end
        end

        context "when tree_path suffixing is configured explicitly" do
          let(:queue) { "suffixed" }
          let(:tree_path) { "ABD" }
          let(:suffix) { "K" }
          let(:message_attributes) do
            {
              request_id: SecureRandom.uuid,
              request_depth: tree_path.length,
              tree_path: tree_path
            }
          end

          before do
            Shoryuken.configure_server do |config|
              Kiev::Shoryuken.suffix_tree_path(config, suffix)
            end
            class SuffixedWorker
              include Shoryuken::Worker
              shoryuken_options queue: "suffixed"

              def perform(_sqs_msg, _body)
                true
              end
            end
            processor.process
          end

          after do
            Shoryuken.configure_server do |config|
              config.server_middleware.remove(Kiev::Shoryuken::Middleware::TreePathSuffix)
            end
          end

          describe "logged entry" do
            subject { Kiev::Test::Log.entries.first }
            it "adds a configured suffix to it" do
              is_expected.to include("tree_path" => tree_path + suffix)
            end
          end
        end

        context "when sensitive data" do
          let(:message_body) { { "password" => "secret" } }

          subject { Kiev::Test::Log.entries.first }

          before { processor.process }

          it "filters logging data" do
            is_expected.to include("body" => "{\"password\":\"[FILTERED]\"}")
          end
        end
      end
    end
  end
end
