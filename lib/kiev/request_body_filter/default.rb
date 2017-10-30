# frozen_string_literal: true

module Kiev
  module RequestBodyFilter
    class Default
      def self.call(request_body, _filtered_params, _ignored_params)
        request_body
      end
    end
  end
end
