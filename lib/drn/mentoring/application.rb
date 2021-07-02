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
      ].freeze

      attr_reader :env, :logger, :root, :db, :session_secret, :settings

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
        when :production
          @settings =
            SETTINGS
              .reduce({}) { |h, key| h.merge!(key => ENV.fetch(key)) }
              .freeze
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

      def initialized?
        !!@initialized
      end

      def init!
        if initialized?
          raise 'An application can only be initialized once'
        else
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

          @initialized = true
        end
        self
      end
    end
  end
end
