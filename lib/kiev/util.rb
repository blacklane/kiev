# frozen_string_literal: true

module Kiev
  module Util
    def self.sanitize(value)
      return unless value

      value.gsub(/[^\w-]/, "")[0...255]
    end

    def self.to_http(value)
      "HTTP_#{value.tr('-', '_').upcase}"
    end
  end
end
