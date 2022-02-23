# frozen_string_literal: true

module Drn
  module Mentoring
    # A resource for loading Mailjet configuration
    class Mailjet
      include Framework::Application::Resource

      def load
        ::Mailjet.configure do |config|
          config.api_key = app.settings[:mailjet_api_key]
          config.secret_key = app.settings[:mailjet_secret_key]
          config.default_from = 'contact@delonnewman.name'
          config.api_version = 'v3.1'
        end
      end
    end
  end
end
