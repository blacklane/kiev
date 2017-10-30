# frozen_string_literal: true

require_relative "base"

module Kiev
  module HTTParty
    def self.headers
      SubrequestHelper.headers
    end
  end
end
