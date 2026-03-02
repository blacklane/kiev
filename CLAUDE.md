# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Kiev is a comprehensive structured logging library for Ruby that produces JSON logs for distributed systems. It tracks HTTP requests across microservices, background jobs, and provides correlation IDs to trace request chains. The library integrates with Rails, Sinatra, Rack, Sidekiq, Que, Shoryuken, Kafka, Her, HTTParty, and other frameworks.

## Running Tests

### Default Test Suite
```bash
bundle exec rake
```
This runs RSpec specs, Minitest tests, and RuboCop.

### Individual Test Suites
```bash
# Run only RSpec tests
bundle exec rake spec

# Run only Minitest integration tests
bundle exec rake test

# Run only RuboCop
bundle exec rake rubocop
```

### Testing with Specific Framework Versions
The project uses gemfiles in `gemfiles/` to test against different framework versions:

```bash
# Test with a specific framework version
BUNDLE_GEMFILE=gemfiles/sidekiq_6.4.gemfile bundle install
BUNDLE_GEMFILE=gemfiles/sidekiq_6.4.gemfile bundle exec rake

# Test with Rails 6.0
BUNDLE_GEMFILE=gemfiles/rails_6.0.gemfile bundle exec rake

# Test Kafka integration
BUNDLE_GEMFILE=gemfiles/ruby_kafka.gemfile bundle exec rake
```

### Testing Que Jobs (requires Postgres)
Que tests require a Postgres database. The test suite expects the `DATABASE_URL` environment variable:

```bash
# Create test database
createdb que_test

# Run Que tests
DATABASE_URL=postgres://username:@localhost/que_test BUNDLE_GEMFILE=gemfiles/que_0.12.3.gemfile bundle exec rake
```

### Testing Sidekiq (requires Redis)
Sidekiq tests require a Redis instance running:

```bash
# Default Redis URL is redis://localhost/15
# Override if needed:
REDIS_URL=redis://localhost:6379/4 bundle exec rake
```

## Architecture

### Core Components

**Kiev::Base** (`lib/kiev/base.rb`)
- Entry point for the public API (`Kiev.event`, `Kiev.payload`, `Kiev[]`)
- Provides convenience methods for each log level (debug, info, warn, error, fatal)
- Manages the request store for per-request contextual data

**Kiev::Config** (`lib/kiev/config.rb`)
- Singleton configuration object
- Defines filtered/ignored parameters, log conditions, propagated fields
- Configurable via `Kiev.configure { |c| ... }` blocks

**Kiev::Logger** (`lib/kiev/logger.rb`)
- Custom Ruby logger that outputs JSON in production and human-readable logs in development mode
- Formatter switches based on `development_mode` config

**Kiev::RequestStore** (`lib/kiev/request_store.rb`)
- Thread-local storage for request-scoped data using the `request_store` gem
- Stores tracking_id, request_id, request_depth, tree_path, and custom fields

### Request Tracing

Kiev uses three key concepts for distributed tracing:

1. **tracking_id/request_id**: UUID that stays constant across the entire request chain
2. **request_depth**: Integer that increments with each service hop (starts at 0)
3. **tree_path**: Lexicographically sortable string that shows branching (e.g., "A", "AB", "AC", "ABA")
   - Odd letters (A, C, E) = synchronous requests
   - Even letters (B, D, F) = asynchronous jobs

### Framework Integrations

**Rack Middleware** (`lib/kiev/rack/`)
- `RequestId`: Extracts/generates tracking IDs from HTTP headers (X-Tracking-Id, X-Request-Id)
- `StoreRequestDetails`: Captures request metadata (verb, path, params, IP, user agent)
- `RequestLogger`: Logs request_finished events with duration and response details
- Stack automatically loaded via `Kiev::Rack` module or Rails Railtie

**Sidekiq** (`lib/kiev/sidekiq/`)
- Server middleware logs job_finished events
- Client middleware propagates tracking context to enqueued jobs
- Enable via `Kiev::Sidekiq.enable`
- Supports Sidekiq 4.2, 5.2, 6.4, 6.5+
- Testing utilities in `Kiev::Sidekiq::Testing` provide version-compatible helpers for creating processors and unit of work in tests

**Shoryuken (SQS)** (`lib/kiev/shoryuken/`)
- Middleware for tracking SQS message processing
- Supports tree_path suffixing for fan-out scenarios (multiple queues subscribed to one SNS topic)
- Enable via `Kiev::Shoryuken.enable`

**Kafka** (`lib/kiev/kafka/`)
- `ContextInjector`: Adds Kiev context to Kafka message headers
- `ContextExtractor`: Extracts Kiev context from consumed messages
- Usage: `Kiev::Kafka.inject_context(headers)` and `Kiev::Kafka.extract_context(message)`

**Que** (`lib/kiev/que/`)
- Base job class `Kiev::Que::Job` that includes request tracing

**Her/Faraday** (`lib/kiev/her_ext/`)
- Middleware that propagates X-Request-Id and other headers to outgoing HTTP requests

**HTTParty** (`lib/kiev/httparty/`)
- Similar propagation for HTTParty-based HTTP clients

### Important Patterns

**Parameter Filtering**: Kiev filters sensitive params (password, token, credit_card_*, etc.) before logging. Configure via `config.filtered_params`.

**Eager Parameter Parsing**: Rails 6+ removed eager JSON/XML parsing. Kiev restores this behavior (enabled by default when Rails is present) to fail fast on malformed payloads. Configure via `config.eager_parameter_parsing`.

**Conditional Logging**: By default, Kiev doesn't log requests to `/ping`, `/health`, `/live`, `/ready`, or static assets. Override via `config.log_request_condition`.

**Development Mode**: Set `config.development_mode = true` for human-readable logs instead of JSON.

## File Structure

- `lib/kiev.rb` - Main entry point that conditionally requires framework integrations
- `lib/kiev/base.rb` - Public API and core functionality
- `lib/kiev/rack/` - Rack middleware components
- `lib/kiev/sidekiq/` - Sidekiq client and server middleware
- `lib/kiev/shoryuken/` - Shoryuken middleware for SQS
- `lib/kiev/kafka/` - Kafka context injection/extraction
- `lib/kiev/request_body_filter/` - Parsers for JSON, XML, form data
- `spec/` - RSpec unit tests
- `test/` - Minitest integration tests for Rails, Sinatra, Sidekiq, Her
- `gemfiles/` - Gemfiles for testing against different framework versions

## Testing Notes

- RSpec tests are in `spec/` and test individual components/units
- Minitest tests are in `test/` and test full framework integrations
- Test helper at `test/helper.rb` sets up LOG_IO and configuration
- LogHelper module provides `logs`, `log_first`, `log_last` helpers for parsing JSON logs
- Integration tests use real framework instances (Combustion for Rails, test apps for Sinatra)
- Sidekiq tests handle version differences (6.4 vs 6.5+) where BasicFetch was removed

## Code Originality & Compliance

When writing code, always implement novel solutions: create new code from scratch or import a compliant library.
Use the `dependency-license-check` skill to verify any library meets our standards before adding it. For complex logic (SQL queries, regex patterns, algorithms), write original implementations tailored to our domain rather than reproducing snippets from external sources with restrictive licensing or use a library that meets our licensing standards.

## Dependency & License Policy

All new dependencies must comply with Blacklane's Open Source Software Policy. **You MUST invoke the `dependency-license-check` skill before adding, installing, or upgrading any dependency. Never add a library without running this check first.** The skill is also used when auditing existing dependencies for compliance. See the `dependency-license-check` skill files for the complete policy, allowed/restricted license matrix, and per-language usage detection rules.
