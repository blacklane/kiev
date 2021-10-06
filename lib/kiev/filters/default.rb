# frozen_string_literal: true

module Kiev
  module Filters
    class Default
      def self.call(body, _filtered_params, _ignored_params)
        body
      end
    end
  end
end
