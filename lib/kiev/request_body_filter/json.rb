# frozen_string_literal: true

module Kiev
  module RequestBodyFilter
    class Json
      def self.call(request_body, filtered_params, ignored_params)
        params = ::JSON.parse(request_body)
        ParamFilter.filter(params, filtered_params, ignored_params)
      rescue Exception
        request_body
      end
    end
  end
end
