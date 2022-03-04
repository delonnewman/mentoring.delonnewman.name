# frozen_string_literal: true

module El
  module Application
    # A resource for loading settings from user and environment variables
    class Settings
      include Resourcable

      def [](key)
        @settings[normalize_key(key)]
      end

      def load!
        return if loaded?

        notify!

        @settings = {}

        load_user_settings!
        load_env!

        @settings.freeze
        loaded!
      end

      def dotenv_path
        case app.env
        when :development
          '.env'
        when :production
          nil
        else
          ".env.#{app.env}"
        end
      end

      private

      def notify!
        if app.production?
          app.logger.info "Initializing application in #{app.env} environment"
        else
          app.logger.info "Initializing application in #{app.env} environment from #{dotenv_path}"
        end
      end

      def normalize_key(key)
        return key if key.is_a?(Symbol)

        key.downcase.to_sym
      end

      def load_settings_from_environment!
        app.class.settings_from_environment.each_with_object(@settings) do |key, h|
          h.merge!(normalize_key(key) => ENV.fetch(key))
        end

        self
      end

      def load_env!
        case app.env
        when :production, :ci
          load_settings_from_environment!
        else
          Dir.chdir(app.root_path)
          @settings.merge!(Dotenv.load(dotenv_path).transform_keys(&method(:normalize_key)))
        end

        self
      end

      def load_user_settings!
        @settings.merge!(app.class.settings)
      end
    end
  end
end
