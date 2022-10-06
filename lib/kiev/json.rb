# frozen_string_literal: true

require "time"

module Kiev
  class JSON
    class << self
      attr_accessor :engine
    end
  end
end

begin
  require "oj"
  Kiev::JSON.engine = :oj
rescue LoadError
  require "json"

  if defined?(ActiveSupport::JSON)
    Kiev::JSON.engine = :activesupport
  elsif defined?(::JSON)
    Kiev::JSON.engine = :json
  end
end

module Kiev
  class JSON
    OJ_OPTIONS_3 = {
      mode: :rails,
      use_as_json: true,
      use_to_json: true
    } # do not do freeze for Oj3 and Rails 4.1

    OJ_OPTIONS_2 = {
      float_precision: 16,
      bigdecimal_as_decimal: false,
      nan: :null,
      time_format: :xmlschema,
      second_precision: 3,
      mode: :compat,
      use_as_json: true,
      use_to_json: true
    }.freeze

    OJ_OPTIONS = (defined?(Oj::VERSION) && Oj::VERSION >= "3") ? OJ_OPTIONS_3 : OJ_OPTIONS_2

    FAIL_JSON = "{\"error_json\":\"failed to generate json\"}"
    NO_JSON = "{\"error_json\":\"no json backend\"}"

    class << self
      def generate(obj)
        if engine == :oj
          oj_generate(obj)
        elsif engine == :activesupport
          activesupport_generate(obj)
        elsif engine == :json
          json_generate(obj)
        else
          NO_JSON.dup
        end
      end

      def logstash(entry)
        entry.each do |key, value|
          entry[key] = if value.respond_to?(:iso8601)
            value.iso8601(3)
          elsif !scalar?(value)
            generate(value)
          elsif value.is_a?(String) && value.encoding != Encoding::UTF_8
            value.encode(
              Encoding::UTF_8,
              invalid: :replace,
              undef: :replace,
              replace: "?"
            )
          elsif value.respond_to?(:infinite?) && value.infinite?
            nil
          else
            value
          end
        end

        generate(entry) << "\n"
      end

      private

      # Arrays excluded here because Elastic indexes very picky:
      # if you have array of mixed things it will complain
      def scalar?(value)
        value.is_a?(String) ||
          value.is_a?(Numeric) ||
          value.is_a?(Symbol) ||
          value.is_a?(TrueClass) ||
          value.is_a?(FalseClass) ||
          value.is_a?(NilClass)
      end

      def oj_generate(obj)
        Oj.dump(obj, OJ_OPTIONS)
      rescue Exception => e
        [FAIL_JSON.dup, obj.inspect, "oj_generate", e.message, e.class.name].join(" - ")
      end

      def activesupport_generate(obj)
        ActiveSupport::JSON.encode(obj)
      rescue Exception
        [FAIL_JSON.dup, obj.inspect, "activesupport_generate"].join(" - ")
      end

      def json_generate(obj)
        ::JSON.generate(obj, quirks_mode: true)
      rescue Exception
        [FAIL_JSON.dup, obj.inspect, "json_generate"].join(" - ")
      end
    end
  end
end
