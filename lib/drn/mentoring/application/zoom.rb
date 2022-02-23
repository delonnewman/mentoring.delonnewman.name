# frozen_string_literal: true

module Drn
  module Mentoring
    # A resource for loading Zoom configuration
    class Zoom
      include Framework::Application::Resource

      attr_reader :client

      def load
        ::Zoom.configure do |config|
          config.api_key = app.settings[:zoom_api_key]
          config.api_secret = app.settings[:zoom_api_secret]
        end

        @client = ::Zoom.new
      end
    end
  end
end
