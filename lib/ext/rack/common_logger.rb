# frozen_string_literal: true

# Disable useless rack logger completely!
# for some reason disable :logging doesn't work for sinatra
module Rack
  class CommonLogger
    def call(env)
      # do nothing
      @app.call(env)
    end
  end
end
