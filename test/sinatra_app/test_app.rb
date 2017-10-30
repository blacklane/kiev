# frozen_string_literal: true

require "xmlsimple"
require "sinatra/namespace"

class TestApp < Sinatra::Base
  include Kiev::Rack

  # Enable error pages that show backtrace and environment information when an unhandled exception occurs.
  # Enabled in development environments by default.
  disable :show_exceptions
  # log exception backtraces to STDERR
  disable :dump_errors
  # allow exceptions to propagate outside of the app
  disable :raise_errors

  use Rack::Parser, parsers: {
    "application/json" => proc { |data| JSON.parse(data) },
    "application/xml"  => proc { |data| XmlSimple.xml_in(data) }
  }

  get("/") { "Hello World" }
  post("/") { "Hello World" }

  post("/post_file") do
    params[:file][:tempfile].read
    params[:file][:tempfile].close
    "Hello World"
  end

  get("/log_in_action") do
    Kiev.logger.info("test")
    "body"
  end

  get("/request_data") do
    Kiev.payload(a: 0.0 / 0, b: BigDecimal.new("1"), c: "test", "c" => "c")
  end

  get("/raise_exception_handled") { raise RuntimeError, "Error" }

  # you should not rescue from Exception here,
  # unless you are using Puma in cluster mode
  # otherwise you will shadow posix signals
  error(StandardError) do |_exception|
    status(500)
    "<h1>Internal\ Server\ Error<\/h1>"
  end

  error(RuntimeError) do |_exception|
    status(502)
    "internal server error"
  end

  get("/raise_exception_unhandled") { raise StandardError, "Error" }

  get("/exception_as_control_flow") { raise KievIgnoredException, "exception message" }

  error(KievIgnoredException) do |exception|
    status(403)
    exception.message
  end

  UUID_PARAM = "(?<uuid>([a-z0-9]){8}-([a-z0-9]){4}-([a-z0-9]){4}-([a-z0-9]){4}-([a-z0-9]){12})"

  register Sinatra::Namespace
  namespace("/admin") do
    get(%r{/resource/#{UUID_PARAM}/test}) { "body" }
  end

  get(%r{/resource/#{UUID_PARAM}/test}) { "body" }

  get("/test_halt") { halt(400, { "Content-Type" => "plain/text" }, "halt response") }

  get("/test_custom_halt") { halt(999) }

  error(999) do
    status(401)
    "custom halt"
  end
end

class TestApp2 < Sinatra::Base
  include Kiev::Rack

  # Enable error pages that show backtrace and environment information when an unhandled exception occurs.
  # Enabled in development environments by default.
  enable :show_exceptions
  # log exception backtraces to STDERR
  enable :dump_errors
  # allow exceptions to propagate outside of the app
  enable :raise_errors

  get("/raise_exception_handled") { raise RuntimeError, "Error" }

  error(RuntimeError) do |_exception|
    status(502)
    "internal server error"
  end

  get("/raise_exception_unhandled") { raise StandardError, "Error" }
end
