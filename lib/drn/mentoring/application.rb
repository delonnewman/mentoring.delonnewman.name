# frozen_string_literal: true

require 'rack/contrib/try_static'

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
      @apps ||= {}
      @apps[env] ||= Application.new(env)
    end

    # Represents the application state
    #
    # TODO: Generalize this and add it to the framework
    class Application
      # Methods that should not be shared in other contexts (see Drn::Mentoring::Controller)
      METHODS_NOT_SHARED = Set[:env, :call, :init!, :main].freeze
      SETTINGS = %w[
        DATABASE_URL
        DOMAIN
        STRIPE_KEY
        STRIPE_PUB_KEY
        MENTORING_SESSION_SECRET
        MAILJET_API_KEY
        MAILJET_SECRET_KEY
        ZULIP_HOST
        ZULIP_BOT_EMAIL
        ZULIP_API_KEY
        ZOOM_API_KEY
        ZOOM_API_SECRET
      ].freeze

      attr_reader :env, :logger, :root, :db, :session_secret, :settings,
                  :zulip_client, :zoom_client, :default_mentor_username

      def initialize(env)
        @env = env
        @logger = Logger.new($stdout, level: log_level)
        @root = Pathname.new(File.join(__dir__, '..', '..', '..')).expand_path
      end

      def log_level
        case env
        when :test
          :warn
        when :production
          :error
        else
          :info
        end
      end

      def dotenv_path
        case env
        when :development
          '.env'
        when :production
          nil
        else
          ".env.#{env}"
        end
      end

      def load_env!
        case env
        when :production, :ci
          @settings = SETTINGS.reduce({}) { |h, key| h.merge!(key => ENV.fetch(key)) }.freeze
        else
          Dir.chdir(root)
          @settings = Dotenv.load(dotenv_path).freeze
        end
        self
      end

      def url_scheme
        case env
        when :test, :development
          'http'
        else
          'https'
        end
      end

      def template_path(*parts, ext: 'html.erb')
        root.join('templates', "#{parts.join('/')}.#{ext}")
      end

      def layout_path(name)
        template_path('layouts', name)
      end

      # Rack interface
      def call(env)
        env['mentoring.app'] = self
        Main.rack.call(env)
      end

      def init!
        raise 'An application can only be initialized once' if initialized?

        if env == :production
          puts "Initializing application in #{env} environment"
        else
          puts "Initializing application in #{env} environment from #{dotenv_path}"
        end

        # TODO: componentize these
        load_env!

        @db = Sequel.connect(settings.fetch('DATABASE_URL'))
        Stripe.api_key = settings.fetch('STRIPE_KEY')
        @session_secret = settings.fetch('MENTORING_SESSION_SECRET')

        Mailjet.configure do |config|
          config.api_key = settings.fetch('MAILJET_API_KEY')
          config.secret_key = settings.fetch('MAILJET_SECRET_KEY')
          config.default_from = 'contact@delonnewman.name'
          config.api_version = 'v3.1'
        end

        @zulip_client = WonderLlama::Client.new(
          host: settings.fetch('ZULIP_HOST'),
          email: settings.fetch('ZULIP_BOT_EMAIL'),
          api_key: settings.fetch('ZULIP_API_KEY')
        )

        Zoom.configure do |config|
          config.api_key = settings.fetch('ZOOM_API_KEY')
          config.api_secret = settings.fetch('ZOOM_API_SECRET')
        end

        @zoom_client = Zoom.new

        @default_mentor_username = 'delon'

        require 'pry' if env == :development

        initialized!

        self
      end

      def initialized?
        !!@initialized
      end

      private

      def initialized!
        @initialized = true
      end
    end
  end
end
