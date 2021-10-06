# frozen_string_literal: true

require_relative "filters/default"
require_relative "filters/xml"
require_relative "filters/json"
require_relative "filters/form_data"

module Kiev
  module RequestBodyFilter
    FILTERED = "[FILTERED]"

    JSON_CONTENT_TYPE = %w(text/json application/json)
    XML_CONTENT_TYPES = %w(text/xml application/xml)
    FORM_DATA_CONTENT_TYPES = %w(application/x-www-form-urlencoded multipart/form-data)

    def self.for_content_type(content_type)
      case content_type
      when *JSON_CONTENT_TYPE
        Filters::Json
      when *XML_CONTENT_TYPES
        Filters::Xml
      when *FORM_DATA_CONTENT_TYPES
        Filters::FormData
      else
        Filters::Default
      end
    end

    def self.filter(content_type, request_body, filtered_params, ignored_params)
      body = request_body.read
      request_body.rewind
      body_filter = for_content_type(content_type)
      body_filter.call(body, filtered_params, ignored_params)
    end
  end
end
