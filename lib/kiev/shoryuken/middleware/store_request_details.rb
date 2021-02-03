# frozen_string_literal: true

require "kiev/shoryuken/context_reader"

module Kiev
  module Shoryuken
    module Middleware
      class StoreRequestDetails
        def call(_worker, _queue, message, _body)
          context_reader = Kiev::Shoryuken::ContextReader.new(message)
          p Config.instance.jobs_propagated_fields
          p Config.instance.all_jobs_propagated_fields
          Config.instance.jobs_propagated_fields.each do |key|
            Kiev[key] = context_reader[key]
          end
          request_store = Kiev::RequestStore.store
          request_store[:background_job] = true
          request_store[:message_id] = message.message_id
          yield
        end
      end
    end
  end
end
