# frozen_string_literal: true

module Kiev
  module RequestStore
    def self.store
      ::RequestStore.store[:kiev] ||= {}
    end

    module Mixin
      def wrap_request_store_13
        ::RequestStore.begin!
        yield
      ensure
        ::RequestStore.end!
        ::RequestStore.clear!
      end

      def wrap_request_store_10
        ::RequestStore.clear!
        yield
      ensure
        ::RequestStore.clear!
      end

      if ::RequestStore::VERSION >= "1.3"
        alias_method :wrap_request_store, :wrap_request_store_13
      else
        alias_method :wrap_request_store, :wrap_request_store_10
      end
    end
  end
end
