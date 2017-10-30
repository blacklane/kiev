# frozen_string_literal: true

require_relative "base"
require "action_view/log_subscriber"
require "action_controller/log_subscriber"

module Kiev
  class Railtie < Rails::Railtie
    initializer("kiev.insert_middleware") do |app|
      app.config.middleware.insert_after(::RequestStore::Middleware, Kiev::Rack::RequestId)
      app.config.middleware.insert_after(Kiev::Rack::RequestId, Kiev::Rack::StoreRequestDetails)
      app.config.middleware.insert_after(ActionDispatch::ShowExceptions, Kiev::Rack::RequestLogger)
    end

    if Config.instance.disable_default_logger
      initializer("kiev.disable_default_logger") do |app|
        app.config.middleware.delete(Rails::Rack::Logger)
        app.config.middleware.insert_before(ActionDispatch::DebugExceptions, Kiev::Rack::SilenceActionDispatchLogger)
        Rails.logger = Config.instance.logger
        app.config.after_initialize do
          Kiev::Rack::SilenceActionDispatchLogger.disabled = app.config.consider_all_requests_local
          remove_existing_log_subscriptions unless Kiev::Config.instance.development_mode
        end
      end
    end

    private

    def remove_existing_log_subscriptions
      ActiveSupport::LogSubscriber.log_subscribers.each do |subscriber|
        case subscriber
        when ActionView::LogSubscriber
          unsubscribe(:action_view, subscriber)
        when ActionController::LogSubscriber
          unsubscribe(:action_controller, subscriber)
        when defined?(ActiveRecord::LogSubscriber) && ActiveRecord::LogSubscriber
          unsubscribe(:active_record, subscriber)
        when defined?(SequelRails::Railties::LogSubscriber) && SequelRails::Railties::LogSubscriber
          unsubscribe(:sequel, subscriber)
        end
      end
    end

    def unsubscribe(component, subscriber)
      events = subscriber.public_methods(false).reject { |method| method.to_s == "call" }
      events.each do |event|
        ActiveSupport::Notifications.notifier.listeners_for("#{event}.#{component}").each do |listener|
          if listener.instance_variable_get("@delegate") == subscriber
            ActiveSupport::Notifications.unsubscribe(listener)
          end
        end
      end
    end
  end
end
