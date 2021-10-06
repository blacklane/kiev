# frozen_string_literal: true

module Kiev
  module Filters
    class Json
      def self.call(body, filtered_params, ignored_params)
        return body unless body.is_a?(String)

        params = ::JSON.parse(body)
        filtered = ParamFilter.filter(params, filtered_params, ignored_params)
        ::JSON.dump(filtered)
      rescue ::JSON::ParserError
        body
      end
    end
  end
end
