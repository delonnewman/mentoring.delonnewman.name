# frozen_string_literal: true
require 'rack/contrib/try_static'

module Drn
  module Mentoring
    def self.resolved_env(env)
      ENV.fetch('RACK_ENV') { env }.to_sym
    end

    def self.current_env
      @current_env || :development
    end

    def self.init!(env = current_env)
      app(env).init!
    end

    def self.app(env = current_env)
      env = resolved_env(env)
      @current_env = env
      @apps ||= {}
      @apps[env] ||= Application.new(env)
    end

    # Represents the application state
    class Application
      # Methods that should not be shared in other contexts (see Drn::Mentoring::Controller)
      METHODS_NOT_SHARED = Set[:env, :call, :init!, :main].freeze
      SETTINGS = %w[DATABASE_URL DOMAIN STRIPE_KEY STRIPE_PUB_KEY MENTORING_SESSION_SECRET].freeze

      attr_reader :env, :logger, :root, :db, :session_secret, :settings

      def initialize(env)
        @env    = env
        @logger = Logger.new($stdout, level: log_level)
        @root   = Pathname.new(File.join(__dir__, '..', '..', '..')).expand_path
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
        else
          ".env.#{env}"
        end
      end

      def load_env!
        case env
        when :production
          @settings = SETTINGS.reduce({}) do |h, key|
            h.merge!(key => ENV.fetch(key))
          end.freeze
        else
          @settings = Dotenv.load(dotenv_path).freeze
        end
        self
      end

      # Rack interface
      def call(env)
        Main.rack.call(env)
      end

      def initialized?
        !!@initialized
      end

      def init!
        if initialized?
          raise "An application can only be initialized once"
        else
          puts "Initializing application in #{env} environment from #{dotenv_path}"
          # TODO: componentize these
          load_env!
          @db = Sequel.connect(settings.fetch('DATABASE_URL'))
          Stripe.api_key = settings.fetch('STRIPE_KEY')
          @session_secret = settings.fetch('MENTORING_SESSION_SECRET')
          @initialized = true
        end
        self
      end
    end
  end
end
