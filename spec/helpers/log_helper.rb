# frozen_string_literal: true

LOG_IO = StringIO.new
ROOT_FOLDER = File.expand_path(File.dirname(__FILE__)).to_s.freeze
DATA_FOLDER = "#{ROOT_FOLDER}/data"

require "json"
module KievHelper
  LOG_IO = StringIO.new

  def enable_log_tracking
    Kiev.configure do |c|
      c.log_path = LOG_IO
    end
  end

  def disable_log_tracking
    Kiev.configure do |c|
      c.log_path = "/dev/null"
    end
  end

  def reset_logs
    LOG_IO.rewind
    LOG_IO.truncate(0)
    @logs = nil
  end

  def logs
    return @logs if @logs
    LOG_IO.rewind
    @logs = LOG_IO.read.split("\n").map(&JSON.method(:parse))
  end

  def log_first
    logs.first
  end

  def log_last
    logs.last
  end
end
