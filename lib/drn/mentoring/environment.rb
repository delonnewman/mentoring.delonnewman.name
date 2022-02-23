# frozen_string_literal: true

require_relative '../framework'

# Application state
require_relative 'application'

module Drn
  module Mentoring
    module_function

    def resolved_env(env)
      ENV.fetch('RACK_ENV') { env }.to_sym
    end

    def current_env
      @current_env || :development
    end

    def init!(env = current_env)
      app(env).init!
    end

    def app(env = current_env)
      env = resolved_env(env)
      @current_env = env
      app_cache[env] ||= Application.new(env)
    end

    def app_cache
      @app_cache ||= {}
    end

    def apps
      app_cache.values
    end
  end
end
