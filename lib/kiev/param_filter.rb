# frozen_string_literal: true

module Kiev
  class ParamFilter
    FILTERED = "[FILTERED]"

    def self.filterable?(params)
      params.respond_to?(:each_with_object)
    end

    def self.filter(params, filtered_params, ignored_params)
      new(filtered_params, ignored_params).call(params)
    end

    def initialize(filtered_params, ignored_params)
      @filtered_params = normalize(filtered_params)
      @ignored_params = normalize(ignored_params)
    end

    def call(params)
      params.each_with_object({}) do |(key, value), acc|
        next if ignored_params.include?(key.to_s)

        if defined?(ActionDispatch) && value.is_a?(ActionDispatch::Http::UploadedFile)
          value = {
            original_filename: value.original_filename,
            content_type: value.content_type,
            headers: value.headers
          }
        end

        acc[key] =
          if filtered_params.include?(key.to_s) && !value.is_a?(Hash)
            FILTERED
          elsif value.is_a?(Hash)
            call(value)
          else
            value
          end
      end
    end

    private

    attr_reader :filtered_params, :ignored_params

    def normalize(params)
      Set.new(params.map(&:to_s))
    end
  end
end
