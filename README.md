# Kiev [![Build Status](https://github.com/blacklane/kiev/workflows/Main%20CI/badge.svg?branch=master)](https://github.com/blacklane/kiev/actions?query=workflow%3A%22Main+CI%22) [![Gem Version](https://badge.fury.io/rb/kiev.svg)](https://badge.fury.io/rb/kiev)

Kiev is a comprehensive logging library aimed at covering a wide range of frameworks and tools from the Ruby ecosystem:

- Rails
- Sinatra
- Rack and other Rack-based frameworks
- Sidekiq
- Que
- Shoryuken
- Her and other Faraday-based libraries
- HTTParty

The main goal of Kiev is consistent logging across distributed systems, like **tracking HTTP requests across various Ruby micro-services**. Kiev will generate and propagate request IDs and make it easy for you to identify service calls and branching requests, **including background jobs triggered by these requests**.

Aside from web requests and background jobs, which are tracked out of the box, Kiev makes it easy to append additional information or introduce **custom events**.

Kiev produces structured logs in the **JSON format**, which are ready to be ingested by ElasticSearch or other similar JSON-driven data stores. It eliminates the need for Logstash in a typical ELK stack.

In **development mode**, Kiev can print human-readable logs - pretty much like the default Rails logger, but including all the additional information that you've provided via Kiev events.

## Install

Add the gem to your `Gemfile`:

```ruby
gem "kiev"
```

Don't forget to `bundle install`.

## Configure

### Rails

Place your configuration under `config/initializers/kiev.rb`:

```ruby
require "kiev"

Kiev.configure do |config|
  config.app = :my_app
  config.development_mode = Rails.env.development?
  config.log_path = Rails.root.join("log", "structured.log") unless Rails.env.development? || $stdout.isatty
end
```

The middleware stack is included automatically via a *Railtie*.

### Sinatra

Somewhere in your code, ideally before the server configuration, add the following lines:

```ruby
require "kiev"

Kiev.configure do |config|
  config.app = :my_app
  config.log_path = File.join("log", "structured.log")
end
```

Within your `Sinatra::Base` implementation, include the `Kiev::Rack` module, in order to register the middleware stack:

```ruby
require "kiev"
require "sinatra/base"

class MyController < Sinatra::Base
  include Kiev::Rack

  use SomeOtherMiddleware

  get "/hello" do
    "world"
  end
end
```

### Rack

Somewhere in your code, ideally before the server configuration, add the following lines:

```ruby
require "kiev"

Kiev.configure do |config|
  config.app = :my_app
  config.log_path = File.join("log", "structured.log")
end
```

Within your `Rack::Builder` implementation, include the `Kiev::Rack` module, in order to register the middleware stack:

```ruby
require "kiev"
require "rack"

app = Rack::Builder.new do
  include Kiev::Rack

  use SomeOtherMiddleware

  run labmda { |env| [ 200, {}, [ "hello world" ] ] }
end

run(app)
```

### Hanami

Place your configuration under `config/initializers/kiev.rb`:

```ruby
require "kiev"

Kiev.configure do |config|
  config.app = :my_app
  config.development_mode = Hanami.env?(:development)
  config.log_path = File.join("log", "structured.log")
end
```

Within your `MyApp::Application` file, include the `Kiev::Hanami` module, in order to register the middleware stack.
The `include` should be added before `configure` block.

```ruby
module MyApp
  class Application < Hanami::Application
    include Kiev::Hanami

    configure do
      # ...
    end
  end
end
```

### Sidekiq

Add the following lines to your initializer code:

```ruby
Kiev::Sidekiq.enable
```

### Shoryuken

Add the following lines to your initializer code:

```ruby
Kiev::Shoryuken.enable
```

The name of the worker class is not logged by default. Configure [`persistent_log_fields` option](#persistent_log_fields) to include `"shoryuken_class"` if you want this.

### AWS SNS

To enhance messages published to SNS topics you can use the ContextInjector:

```ruby
sns_message = { topic_arn: "...",  message: "{...}" }
Kiev::Kafka.inject_context(sns_message[:message_attributes])

```

After this operation the message attributes will also include required context for the Kiev logger.

### Kafka

To enhance messages published to Kafka topics you can use the ContextInjector:

```ruby
Kiev::Kafka.inject_context(headers)
```

After this operation the headers variable will also include required context for the Kiev logger.

If you have a consumed `Kafka::FetchedMessage` you can extract logger context with: 

```ruby
Kiev::Kafka.extract_context(message)
```

This will work regardless if headers are in HTTP format, e.g. `X-Tracking-Id` or plain field names: `tracking_id`. Plus the `message_key` field will contain the key of processed message. In case you want to log some more fields configure `persistent_log_fields` and `jobs_propagated_fields`.  

### Que

Add the following lines to your initializer code:

```ruby
require "kiev/que/job"

class MyJob < Kiev::Que::Job
  ...
end
```

### Her

Add the following lines to your initializer code:

```ruby
Her::API.setup(url: "https://api.example.com") do |c|
  c.use Kiev::HerExt::ClientRequestId
  # other middleware
end
```

## Loading only the required parts

You can load only parts of the gem, if you don't want to use all features:

```ruby
require "kiev/her_ext/client_request_id"
```

## Logging

### Requests

For web requests the Kiev middleware will log the following information by default:

```json
{
  "application":"my_app",
  "event":"request_finished",
  "level":"INFO",
  "timestamp":"2017-01-27T16:11:44.123Z",
  "host":"localhost",
  "verb":"GET",
  "path":"/",
  "params":"{\"hello\":\"world\",\"password\":\"[FILTERED]\"}",
  "ip":"127.0.0.1",
  "request_id":"UUID",
  "request_depth":0,
  "route":"RootController#index",
  "user_agent":"curl/7.50.1",
  "status":200,
  "request_duration":62.3773,
  "body":"See #log_response_body_condition",
  "error_message": "...",
  "error_class": "...",
  "error_backtrace": "...",
  "tree_path": "ACE",
  "tree_leaf": true
}
```

* `params` attribute will store both query parameters and request body fields (as long as they are parseable). Sensitive fields will be filtered out - see the `#filtered_params` option.

* `request_id` is the correlation ID and will be the same across all requests within a chain of requests. It's represented as a UUID (version 4). (currently deprecated in favor of a new name: `tracking_id`)

* `tracking_id` is the correlation ID and will be the same across all requests within a chain of requests. It's represented as a UUID (version 4). If not provided the value is seeded from deprecated `request_id`. 

* `request_depth` represents the position of the current request within a chain of requests. It starts with 0.

* `route` attribute will be set to either the Rails route (`RootController#index`) or Sinatra route (`/`) or the path, depending on the context.

* `request_duration` is measured in miliseconds.

* `body` attribute coresponds to the response body and will be logged depending on the `#log_response_body_condition` option.

* `tree_path` attribute can be used to follow the branching of requests within a chain of requests. It's a lexicographically sortable string.

* `tree_leaf` points out that this request is a leaf in the request chain tree structure.

### Background jobs

For background jobs, Kiev will log the following information by default:

```json
{
  "application":"my_app",
  "event":"job_finished",
  "level":"INFO",
  "timestamp":"2017-01-27T16:11:44.123Z",
  "job_name":"name",
  "params": "...",
  "jid":123,
  "request_id":"UUID",
  "request_depth":0,
  "request_duration":0.000623773,
  "error_message": "...",
  "error_class": "...",
  "error_backtrace": "...",
  "tree_path": "BDF",
  "tree_leaf": true
}
```

### Appending data to the request log entry

You can also append **arbitrary data** to the request log by calling:

```ruby
# Append structured data (will be merged)
Kiev.payload(first_name: "john", last_name: "smith")

# Same thing
Kiev[:first_name] = "john"
Kiev[:last_name] = "smith"
```

### Other events

Kiev allows you to log custom events as well.

The recommended way to do this is by using the `#event` method:

```ruby
# Log event without any data
Kiev.event(:my_event)

# Log structured data (will be merged)
Kiev.event(:my_event, { some_array: [1, 2, 3] })

# Log other data types (will be available under the `message` key)
Kiev.event(:my_event, "hello world")
```

However, `Kiev.logger` implements the Ruby `Logger` class, so all the other methods are available as well:

```ruby
Kiev.logger.info("hello world")
Kiev.logger.debug({ first_name: "john", last_name: "smith" })
```

Note that, even when logging custom events, Kiev **will try to append request information** to the entries: the HTTP `verb` and `path` for web request or `job_name` and `jid` for background jobs. The payload, however, will be logged only for the `request_finished` or `job_finished` events. If you want to add a payload to a custom event, use the second argument of the `event` method.

## Advanced configuration

### development_mode

Kiev offers human-readable logging for development purposes. You can enable it via the `development_mode` option:

```ruby
Kiev.configure do |config|
  config.development_mode = Rails.env.development?
end
```

### filtered_params

By default, Kiev filters out the values for the following parameters:

- client_secret
- token
- password,
- password_confirmation
- old_password
- credit_card_number
- credit_card_cvv

You can override this behaviour via the `filtered_params` option:

```ruby
Kiev.configure do |config|
  config.filtered_params = %w(email first_name last_name)
end
```

### ignored_params

By default, Kiev ignores the following parameters:

- controller
- action
- format
- authenticity_token
- utf8

You can override this behaviour via the `ignored_params` option:

```ruby
Kiev.configure do |config|
  config.ignored_params = %w(some_field some_other_field)
end
```

### log_request_condition

By default, Kiev doesn't log requests to `/ping` or `/health` or requests to assets.

You can override this behaviour via the `log_request_condition` option, which should be a `proc` returning a `boolean`:

```ruby
Kiev.configure do |config|
  config.log_request_condition = proc do |request, response|
    !%r{(^(/ping|/health))|(\.(js|css|png|jpg|gif)$)}.match(request.path)
  end
end
```

### log_request_error_condition

Kiev logs Ruby exceptions. By default, it won't log the exceptions produced by 404s.

You can override this behaviour via the `log_request_error_condition` option, which should be a `proc` returning a `boolean`:

```ruby
Kiev.configure do |config|
  config.log_request_error_condition = proc do |request, response|
    response.status != 404
  end
end
```

### log_response_body_condition

Kiev can log the response body. By default, it will only log the response body when the status code is in the 4xx range and the content type is JSON or XML.

You can override this behaviour via the `log_response_body_condition` option, which should be a `proc` returning a `boolean`:

```ruby
Kiev.configure do |config|
  config.log_response_body_condition = proc do |request, response|
    response.status >= 400 && response.status < 500 && response.content_type =~ /(json|xml)/
  end
end
```

### persistent_log_fields

If you need to log some data for every event in the session (e.g. the user ID), you can do this via the `persistent_log_fields` option.

```ruby
Kiev.configure do |config|
  config.persistent_log_fields = [:user_id]
end

# Somewhere in application
before do
  Kiev[:user_id] = current_user.id
end

get "/" do
  "hello world"
end
```

## nginx

If you want to log 499 and 50x errors in nginx, which will not be captured by Ruby application, consider adding this to your nginx configuration:

```
log_format kiev '{"application":"app_name", "event":"request_finished",'
  '"timestamp":"$time_iso8601", "request_id":"$http_x_request_id",'
  '"user_agent":"$http_user_agent", "status":$status,'
  '"request_duration_seconds":$request_time, "host":"$host",'
  '"verb":"$request_method", "path":"$request_uri", "tree_path": "$http_x_tree_path"}';

log_format simple_log '$remote_addr - $remote_user [$time_local] '
                       '"$request" $status $bytes_sent '
                       '"$http_referer" "$http_user_agent"';

map $status $not_loggable {
  ~(499) 0;
  default 1;
}

map $status $loggable {
  ~(499) 1;
  default 0;
}

server {
  access_log /var/log/nginx/access.kiev.log kiev if=$loggable;
  access_log /var/log/nginx/access.log simple_log if=$not_loggable;

  location = /50x.html {
    access_log /var/log/nginx/access.kiev.log kiev;
  }
}
```

If you'd like to measure nginx queue latency, add the following to your nginx configuration:

```
server {
  ...
  proxy_set_header X-Request-Start "${msec}";
  ...
}
```

Other libs/technologies using `X-Request-Start` are [rack-timeout](https://github.com/heroku/rack-timeout) and [NewRelic](https://docs.newrelic.com/docs/apm/applications-menu/features/request-queue-server-configuration-examples). There's no [support for ELB](https://forums.aws.amazon.com/message.jspa?messageID=396283) :(

## Logstash, Logrotate, Filebeat

Kiev does not provide facilities to log directly to ElasticSearch. This is done for simplicity. Instead we recommend using [Filebeat](https://www.elastic.co/products/beats/filebeat) to deliver logs to ElasticSearch.

When storing logs on disk, we recommend using Logrotate in truncate mode.

You can use [jq](https://stedolan.github.io/jq/) to traverse JSON log files, when you're not running Kiev in *development mode*.

## Suffixing `tree_path`

Kiev is built upon the assumption that one request is handled once. This isn't always true.

A practical example: multiple Amazon SQS queues subscribed to one Amazon SNS topic. You send one message to SNS and queues receive identical copies that are impossible to distinguish in the trace without any help from the outside.

You can solve this by adding a fixed unique suffix inside each queue processor. Preferably a single character with an even number in the alphabet (B, D, F and so on), to maintain the notion of "asynchronous processing" used throughout Kiev.

For a combination of SNS and [Shoryuken](https://github.com/phstc/shoryuken) (SQS consumer). Here's how you can use it:

* Enable "Raw Message Delivery" in your SQS-to-SNS subscriptions
* On sender, write `Kiev::SubrequestHelper.payload` into the message attributes
* On each receiver, use `Kiev::Shoryuken::suffix_tree_path` with a unique tag, like this:

  ```ruby
  # Suffix a single worker class:
  class MyWorker
    include Shoryuken::Worker
    Kiev::Shoryuken.suffix_tree_path(self, "B")
    # ...
  end

  # Or use a suffix process-wide:
  Shoryuken.configure_server do |config|
    Kiev::Shoryuken.suffix_tree_path(config, "B")
  end
  ```

Here's an example of the possble `tree_path` sequence you could get by configuring two consumers with suffixes `1` and `2` (note ordering by `tree_path`):

| `tree_path` |                             Meaning                             |
|-------------|-----------------------------------------------------------------|
| `A`         | An entry point into the system, a synchronous request           |
| `AB`        | Background job caused by `A` executed                           |
| `ABA`       | Synchoronous request made from `AB`                             |
| `ABD`       | _(Not logged by Kiev itself)_ `AB` sends out an SNS message     |
| `ABD1`      | Message `ABD` handled by susbcriber `1`                         |
| `ABD1A`     | Synchronous request sent by `1` when handling the message `ABD` |
| `ABD1C`     | Synchronous request sent by `1` when handling the message `ABD` |
| `ABD2`      | Message `ABD` handled by susbcriber `2`                         |
| `ABD2A`     | Synchronous request sent by `2` when handling the message `ABD` |
| `ABF`       | Another backgound job from `AB` executed                        |
| `AD`        | Background job caused by `A` executed                           |
| `AE`        | Synchronous request made from `A`                               |

Without suffixing you won't see at a glance who made the request `ABDC` and you will have two entries for both `ABD` and `ABDA`. As different subscribers may log different fields, you might be able to tell apart `ABD`s. But both `ABDA`s could happen on the same node and be logged with the same lines of code.

## Alternatives

### Logging

- [semantic_logger](http://rocketjob.github.io/semantic_logger/)
- [lograge](https://github.com/roidrage/lograge)
- [logging](https://github.com/TwP/logging)

### Request-Id

- [Pliny::Middleware::RequestID](https://github.com/interagent/pliny/blob/master/lib/pliny/middleware/request_id.rb)
- [ActionDispatch::RequestId](http://api.rubyonrails.org/classes/ActionDispatch/RequestId.html)
- [request_id](https://github.com/remind101/request_id)

## Development

Pull the code:

```
git clone git@github.com:blacklane/kiev.git
```

Run tests:

```sh
bundle exec rake
```

Run tests for different rubies, frameworks and framework versions:

```sh
# Create a Postgres test database for Que
createdb que_test

# Run the tests (replace myuser with your username)
DATABASE_URL=postgres://myuser:@localhost/que_test bundle exec wwtd
```
