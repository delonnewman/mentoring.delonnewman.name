# frozen_string_literal: true

module Mentoring
  # A resource for Rack::MiniProfiler configuration
  class Profiling < Application.Resource()
    attr_reader :instance

    start do
      require 'rack-mini-profiler'
      Rack::MiniProfiler.config.authorization_mode = app.production? ? :allow_authorized : :allow_all
    end
  end
end
