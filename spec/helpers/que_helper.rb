# https://github.com/chanks/que/blob/master/spec/spec_helper.rb
# frozen_string_literal: true

require "uri"
require "pg"

# Handy constants for initializing PG connections:
QUE_URL = ENV["DATABASE_URL"] || "postgres://postgres:@localhost/que_test"

NEW_PG_CONNECTION = proc do
  uri = URI.parse(QUE_URL)
  pg = PG::Connection.open(
    host: uri.host,
    user: uri.user,
    password: uri.password,
    port: uri.port || 5432,
    dbname: uri.path[1..-1]
  )

  # Avoid annoying NOTICE messages in specs.
  pg.async_exec("SET client_min_messages TO 'warning'")
  pg
end

Que.connection = NEW_PG_CONNECTION.call
QUE_ADAPTERS = { pg: Que.adapter }

# We use Sequel to examine the database in specs.
require "sequel"
DB = Sequel.connect(QUE_URL)
# DB.loggers << Logger.new($stdout)

if ENV["CI"]
  DB.synchronize do |conn|
    puts "Ruby #{RUBY_VERSION}"
    puts "Sequel #{Sequel::VERSION}"
    puts conn.async_exec("SELECT version()").to_a.first["version"]
  end
end

# Reset the table to the most up-to-date version.
DB.drop_table?(:que_jobs)
Que::Migrations.migrate!
