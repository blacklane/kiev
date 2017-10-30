# frozen_string_literal: false

module Kiev
  module Base52
    KEYS = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz".freeze
    BASE = KEYS.length.freeze

    def self.encode(num)
      return KEYS[0] if num == 0
      return nil if num < 0

      str = ""
      while num > 0
        str.prepend(KEYS[num % BASE])
        num /= BASE
      end
      str
    end
  end
end
