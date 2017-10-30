# frozen_string_literal: true

require "spec_helper"

if defined?(::Que::Job)
  describe Kiev::Que::Job do
    around do |spec|
      Que.adapter = QUE_ADAPTERS[:pg]
      Que.worker_count = 0
      Que.mode = :async
      Que.wake_interval = nil

      spec.run

      Que.mode = :off
      DB[:que_jobs].delete
      # A bit of lint: make sure that no advisory locks are left open.
      unless DB[:pg_locks].where(locktype: "advisory").empty?
        stdout.info("Advisory lock left open: #{desc} @ #{line}")
      end
    end

    class GlobalStore
      class << self
        attr_accessor :passed_args
      end
    end

    class TestJob < Kiev::Que::Job
      def run(*argument)
        GlobalStore.passed_args = argument
      end
    end

    class ErrorJob < Kiev::Que::Job
      def run(*argument)
        GlobalStore.passed_args = argument
        GlobalStore.undefined_method
      end
    end

    include KievHelper

    before do
      enable_log_tracking
      reset_logs
      Kiev::RequestStore.store.clear
      Kiev::RequestStore.store[:request_id] = "test"
      Kiev::RequestStore.store[:request_depth] = 0
      Kiev::RequestStore.store[:tree_path] = "Q"
      GlobalStore.passed_args = nil
    end

    after do
      disable_log_tracking
    end

    it "works with sync run" do
      TestJob.run("Hello world!")
      expect(GlobalStore.passed_args).to eq(["Hello world!"])
      expect(log_first).to eq(nil)
    end

    it "works with sync enqueue" do
      ::Que.mode = :sync
      TestJob.enqueue("Hello world!")
      expect(GlobalStore.passed_args).to eq(["Hello world!"])
      expect(log_first).to eq(nil)
    end

    it "works with async enqueue" do
      TestJob.enqueue("Hello world!")
      Kiev::RequestStore.store.clear
      Que::Job.work
      expect(GlobalStore.passed_args).to eq(["Hello world!"])
      expect(log_first["application"]).to eq("test_app")
      expect(log_first["event"]).to eq("job_finished")
      expect(log_first["job_name"]).to eq("TestJob")
      expect(log_first["level"]).to eq("INFO")
      expect(log_first["params"]).to eq("[\"Hello world!\"]")
      expect(log_first["request_depth"]).to eq(1)
      expect(log_first["request_id"]).to eq("test")
      expect(log_first["tree_path"]).to eq("QB")
      expect(log_first["tree_leaf"]).to eq(true)
      expect(log_first["request_duration"]).to be
      expect(log_first["timestamp"]).to be
      expect(log_first["error_class"]).to be_nil
      expect(log_first["error_message"]).to be_nil
      expect(log_first["error_backtrace"]).to be_nil
      expect(Kiev::RequestStore.store[:request_id]).to be_nil
    end

    it "logs error for async enqueue" do
      ErrorJob.enqueue("Hello world!")
      Kiev::RequestStore.store.clear
      Que::Job.work
      expect(GlobalStore.passed_args).to eq(["Hello world!"])
      expect(log_first).to be
      expect(log_first["application"]).to eq("test_app")
      expect(log_first["event"]).to eq("job_finished")
      expect(log_first["job_name"]).to eq("ErrorJob")
      expect(log_first["level"]).to eq("INFO")
      expect(log_first["params"]).to eq("[\"Hello world!\"]")
      expect(log_first["request_depth"]).to eq(1)
      expect(log_first["request_id"]).to eq("test")
      expect(log_first["tree_path"]).to eq("QB")
      expect(log_first["tree_leaf"]).to eq(true)
      expect(log_first["request_duration"]).to be
      expect(log_first["timestamp"]).to be
      expect(log_first["error_class"]).to eq("NoMethodError")
      expect(log_first["error_message"]).to eq("undefined method `undefined_method' for GlobalStore:Class")
      expect(log_first["error_backtrace"]).to be
      expect(Kiev::RequestStore.store[:request_id]).to be_nil
    end

    it "does not log error for sync enqueue" do
      ::Que.mode = :sync
      expect { ErrorJob.enqueue("Hello world!") }.to raise_error(NoMethodError)
      expect(GlobalStore.passed_args).to eq(["Hello world!"])
      expect(log_first).to eq(nil)
    end
  end
end
