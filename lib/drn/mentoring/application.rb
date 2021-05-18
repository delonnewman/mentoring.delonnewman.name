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

      attr_reader :env, :logger, :root, :db, :session_secret

      def initialize(env)
        @env    = env
        @logger = Logger.new($sterr)
        @root   = Pathname.new(File.join(__dir__, '..', '..', '..')).expand_path
      end

      def dotenv_path
        case env
        when :test
          '.env.test'
        else
          '.env'
        end
      end

      def load_env!
        Dotenv.load!(dotenv_path)
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
          logger.info "Initializing application in #{env} environment from #{dotenv_path}"
          # TODO: componentize these
          load_env!
          @db = Sequel.connect(ENV.fetch('DATABASE_URL'))
          Stripe.api_key = ENV.fetch('STRIPE_KEY')
          @session_secret = ENV.fetch('MENTORING_SESSION_SECRET')
          @initialized = true
        end
        self
      end
    end
  end
end
