# frozen_string_literal: true

require "json"

module Kiev
  # Test helpers for testing both Kiev itself and products that use it.
  module Test
    module Log
      STREAM = StringIO.new

      module_function

      def configure
        @logs = []
        Kiev.configure do |c|
          c.log_path = STREAM
        end
      end

      def clear
        STREAM.rewind
        STREAM.truncate(0)
        @logs = []
      end

      def entries
        return @logs unless @logs.empty?

        @logs = raw_logs.each_line.map(&::JSON.method(:parse))
      rescue StandardError
        puts raw_logs
        raise
      end

      def raw_logs
        STREAM.string
      end
    end
  end
end
