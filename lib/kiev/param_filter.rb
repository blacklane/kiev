# frozen_string_literal: true

module Kiev
  module ParamFilter
    FILTERED = "[FILTERED]"

    def self.filter(params, filtered_params, ignored_params)
      params.each_with_object({}) do |(key, value), acc|
        next if ignored_params.include?(key)

        if defined?(ActionDispatch) && value.is_a?(ActionDispatch::Http::UploadedFile)
          value = {
            original_filename: value.original_filename,
            content_type: value.content_type,
            headers: value.headers
          }
        end

        acc[key] =
          if filtered_params.include?(key) && !value.is_a?(Hash)
            FILTERED
          elsif value.is_a?(Hash)
            filter(value, filtered_params, ignored_params)
          else
            value
          end
      end
    end
  end
end
