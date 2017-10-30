# frozen_string_literal: true

require "oga"

module Kiev
  module RequestBodyFilter
    class Xml
      def self.call(request_body, filtered_params, _ignored_params)
        document = Oga.parse_xml(request_body)
        filtered_params.each do |param|
          sensitive_param = document.at_xpath("//#{param}/text()")
          sensitive_param.text = FILTERED if sensitive_param.respond_to?(:text=)
        end
        document.to_xml
      end
    end
  end
end
