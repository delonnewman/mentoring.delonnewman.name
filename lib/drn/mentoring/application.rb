# frozen_string_literal: true
require 'rack/contrib/try_static'

module Drn
  module Mentoring
    def self.resolved_env(env)
      ENV.fetch('RACK_ENV') { env }.to_sym
    end

    def self.init!(env = :development)
      app(env).init!
    end

    def self.app(env = :development)
      env = resolved_env(env)
      @apps ||= {}
      @apps[env] ||= Application.new(env)
    end

    # Represents the application state
    class Application
      # Methods that should not be shared in other contexts (see Drn::Mentoring::Controller)
      METHODS_NOT_SHARED = Set[:env, :call, :init!, :main].freeze

      attr_reader :env, :logger, :root, :db

      def initialize(env)
        @env    = env
        @logger = Logger.new($stdout)
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
          Dotenv.load!(dotenv_path)
          @db = Sequel.connect(ENV.fetch('DATABASE_URL'))
          Stripe.api_key = ENV.fetch('STRIPE_KEY')
          @initialized = true
        end
        self
      end
    end
  end
end
