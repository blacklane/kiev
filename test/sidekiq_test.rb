# frozen_string_literal: true

require_relative "helper"

if defined?(Sidekiq)
  class SidekiqTest < MiniTest::Spec
    include LogHelper

    class CustomWorker
      include Sidekiq::Worker
      def perform(_args)
        1
      end
    end

    class SubWorker
      include Sidekiq::Worker
      def perform(_args)
        CustomWorker.perform_async("test")
        2
      end
    end

    class ErrorWorker
      include Sidekiq::Worker
      def perform(_args)
        CustomWorker.undefined_method
      end
    end

    before do
      Sidekiq.redis = REDIS
      Sidekiq.redis(&:flushdb)
      Kiev::RequestStore.store.clear
    end

    def run_sidekiq(opts = {})
      msg = Sidekiq.dump_json({ "class" => CustomWorker.to_s, "args" => ["test"] }.merge(opts))
      boss = Minitest::Mock.new
      boss.expect(:options, { queues: ["default"] }, [])
      boss.expect(:options, { queues: ["default"] }, [])
      processor = Sidekiq::Processor.new(boss)
      boss.expect(:processor_done, nil, [processor])
      processor.process(Sidekiq::BasicFetch::UnitOfWork.new("queue:default", msg))
    rescue NoMethodError
      # do nothing, for CustomWorker.undefined_method
    end

    it "server middleware logs successful job" do
      run_sidekiq
      assert_equal("SidekiqTest::CustomWorker", log_first["job_name"])
      assert_equal("job_finished", log_first["event"])
      assert_equal("INFO", log_first["level"])
      assert_equal("[\"test\"]", log_first["params"])
      assert_equal(true, log_first["tree_leaf"])
      assert_equal("B", log_first["tree_path"])
      refute_empty(log_first["timestamp"])
      refute_empty(log_first["request_id"])
      refute_empty(log_first["tracking_id"])
      refute_nil(log_first["request_duration"])
      assert_equal(0, log_first["request_depth"])
      assert_nil(log_first["error_class"])
      assert_nil(log_first["error_message"])
      assert_nil(log_first["error_backtrace"])
      assert_nil(Kiev::RequestStore.store[:request_id])
      assert_nil(Kiev::RequestStore.store[:tracking_id])
    end

    it "server middleware logs error job" do
      run_sidekiq("class" => ErrorWorker.to_s)
      assert_equal("SidekiqTest::ErrorWorker", log_first["job_name"])
      assert_equal("job_finished", log_first["event"])
      assert_equal("ERROR", log_first["level"])
      assert_equal("[\"test\"]", log_first["params"])
      refute_empty(log_first["timestamp"])
      refute_empty(log_first["request_id"])
      refute_empty(log_first["tracking_id"])
      refute_nil(log_first["request_duration"])
      assert_equal(0, log_first["request_depth"])
      assert_equal("NoMethodError", log_first["error_class"])
      assert_equal(
        "undefined method `undefined_method' for SidekiqTest::CustomWorker:Class",
        log_first["error_message"].lines.first.chomp
      )
      refute_nil(log_first["error_backtrace"])
      assert_nil(Kiev::RequestStore.store[:request_id])
    end

    it "server middleware preserves existing request_id" do
      run_sidekiq("request_id" => "test")
      assert_equal("test", log_first["request_id"])
      assert_equal("test", log_first["tracking_id"])
      assert_nil(Kiev::RequestStore.store[:request_id])
      assert_nil(Kiev::RequestStore.store[:tracking_id])
    end

    it "server middleware generates new request_id each time" do
      run_sidekiq
      run_sidekiq
      refute_equal(log_last["request_id"], log_first["request_id"])
      refute_equal(log_last["tracking_id"], log_first["tracking_id"])
    end

    it "server job propagates request_id to underlying job" do
      queue = Sidekiq.redis { |r| r.lrange("queue:default", 0, -1) }.map(&JSON.method(:parse))
      assert_equal(queue.length, 0)
      run_sidekiq("class" => SubWorker.to_s)
      queue = Sidekiq.redis { |r| r.lrange("queue:default", 0, -1) }.map(&JSON.method(:parse))
      assert_equal(queue.length, 1)
      assert_equal(queue.first["class"], "SidekiqTest::CustomWorker")
      assert_equal(queue.first["request_id"], log_first["request_id"])
      assert_equal(queue.first["tracking_id"], log_first["tracking_id"])
    end

    it "client middleware stores request_id in job" do
      Kiev::RequestStore.store[:request_id] = "test"
      mw = Kiev::Sidekiq::ClientRequestId.new

      msg = {}
      mw.call(nil, msg, nil, nil) {}
      assert_equal("test", msg["request_id"])

      msg = { "request_id" => "not_test" }
      mw.call(nil, msg, nil, nil) {}
      assert_equal("test", msg["request_id"])
    end

    it "client middleware stores tree_path in job" do
      Kiev::RequestStore.store[:tree_path] = "Q"
      mw = Kiev::Sidekiq::ClientRequestId.new

      msg = {}
      mw.call(nil, msg, nil, nil) {}
      assert_equal("QB", msg["tree_path"])

      msg = { "tree_path" => "not_test" }
      mw.call(nil, msg, nil, nil) {}
      assert_equal("QD", msg["tree_path"])
    end
  end
end
