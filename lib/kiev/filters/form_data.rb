# frozen_string_literal: true

module Kiev
  module Filters
    class FormData
      def self.call(body, filtered_params, ignored_params)
        params = ::Rack::Utils.parse_nested_query(body)
        ParamFilter.filter(params, filtered_params, ignored_params)
      end
    end
  end
end
