# frozen_string_literal: true

module Drn
  module Mentoring
    # A resource for Rack::MiniProfiler configuration
    class Profiler
      include Framework::Application::Resource

      attr_reader :instance

      def load
        require 'rack-mini-profiler'
        Rack::MiniProfiler.config.authorization_mode = app.env == :production ? :allow_authorized : :allow_all
      end
    end
  end
end
