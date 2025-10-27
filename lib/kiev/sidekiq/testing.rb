# frozen_string_literal: true

module Kiev
  module Sidekiq
    # Testing utilities for Sidekiq version compatibility
    # This module provides helpers for testing Kiev with different Sidekiq versions (6.4, 6.5+)
    module Testing
      class << self
        # Creates a Sidekiq Processor instance compatible with the current Sidekiq version
        #
        # Sidekiq 4.x-5.x: Processor.new(boss)
        # Sidekiq 6.0-6.4: Processor.new(boss, options)
        # Sidekiq 6.5+: Processor.new(config) where config must be a proper config object
        #
        # @param boss [Object] Boss object for Sidekiq 6.4 and earlier (optional for 6.5+)
        # @return [Sidekiq::Processor] A processor instance
        def create_processor(boss = nil)
          arity = ::Sidekiq::Processor.instance_method(:initialize).arity
          version = ::Gem::Version.new(::Sidekiq::VERSION)

          if arity == 2
            # Sidekiq 6.0-6.4 takes two arguments: boss, options
            boss.options ? ::Sidekiq::Processor.new(boss, boss.options) : ::Sidekiq::Processor.new(boss, {})
          elsif arity == 1 && version >= ::Gem::Version.new("6.5.0")
            # Sidekiq 6.5+ takes one argument (config object)
            # Use Sidekiq itself as config since it has all the necessary methods
            ::Sidekiq::Processor.new(::Sidekiq)
          else
            # Sidekiq 4.x-5.x takes one argument (boss)
            ::Sidekiq::Processor.new(boss)
          end
        end

        # Creates a UnitOfWork instance compatible with the current Sidekiq version
        #
        # Sidekiq 6.4 and earlier: UnitOfWork.new(queue, job)
        # Sidekiq 6.5+: UnitOfWork.new(queue, job, config)
        #
        # @param queue [String] The queue name (e.g., "queue:default")
        # @param job [String] The serialized job JSON
        # @return [Sidekiq::BasicFetch::UnitOfWork] A unit of work instance
        def create_unit_of_work(queue, job)
          if ::Sidekiq::BasicFetch::UnitOfWork.members.include?(:config)
            # Sidekiq 6.5+ requires config parameter
            ::Sidekiq::BasicFetch::UnitOfWork.new(queue, job, ::Sidekiq)
          else
            # Sidekiq 6.4 and earlier
            ::Sidekiq::BasicFetch::UnitOfWork.new(queue, job)
          end
        end

        # Returns true if the current Sidekiq version uses the new Processor API (6.5+)
        # @return [Boolean]
        def new_processor_api?
          version = ::Gem::Version.new(::Sidekiq::VERSION)
          version >= ::Gem::Version.new("6.5.0")
        end
      end
    end
  end
end
