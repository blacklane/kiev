# frozen_string_literal: true

require "nokogiri"

module Kiev
  module Filters
    class Xml
      FORMAT_OPTIONS = [
        Nokogiri::XML::Node::SaveOptions::AS_XML,
        Nokogiri::XML::Node::SaveOptions::NO_DECLARATION
      ]

      def self.call(body, filtered_params, _ignored_params)
        return body unless body.is_a?(String)

        document = Nokogiri::XML(body) { |config| config.strict.noent }
        filtered_params.each do |param|
          sensitive_param = document.at_xpath("//#{param}/text()")
          sensitive_param.content = ParamFilter::FILTERED if sensitive_param.respond_to?(:content=)
        end
        document.to_xml(save_with: FORMAT_OPTIONS.join).strip
      rescue Nokogiri::XML::SyntaxError
        body
      end
    end
  end
end
