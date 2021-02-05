# frozen_string_literal: true

require File.join(File.dirname(__FILE__), "lib/kiev/version")

Gem::Specification.new do |spec|
  spec.name          = "kiev"
  spec.version       = Kiev::VERSION
  spec.authors       = ["Blacklane"]
  spec.licenses      = ["MIT"]

  spec.summary       = "Distributed logging to JSON integrated with various Ruby frameworks and tools"
  spec.description   = "Kiev is a logging tool aimed at distributed environments. It logs to JSON, while providing "\
                        "human-readable output in development mode. It integrates nicely with Rails, Sinatra and other"\
                        " Rack-based frameworks, Sidekiq, Que, HTTParty, Her and other Faraday-based HTTP clients."
  spec.homepage      = "https://github.com/blacklane/kiev"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.required_ruby_version = ">= 2.5"
  spec.add_dependency "oga", "~> 2.2"
  spec.add_dependency "rack", ">= 1", "< 3"
  spec.add_dependency "request_store", ">= 1.0", "< 1.4"
  spec.add_dependency "ruby_dig", "~> 0.0.2" # to support ruby 2.2
  spec.add_development_dependency "rake", "~> 0"
  spec.add_development_dependency "rspec", "~> 0"
  spec.add_development_dependency "rubocop", "~> 0.54"
end
