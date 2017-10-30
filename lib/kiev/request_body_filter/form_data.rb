# frozen_string_literal: true

module Kiev
  module RequestBodyFilter
    class FormData
      def self.call(request_body, filtered_params, ignored_params)
        params = ::Rack::Utils.parse_nested_query(request_body)
        ParamFilter.filter(params, filtered_params, ignored_params)
      end
    end
  end
end
