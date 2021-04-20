require 'rack/contrib/try_static'

module Drn
  module Mentoring
    # Represents the application state
    class Application

      attr_reader :env, :logger, :root, :db

      def initialize
        @env      = ENV.fetch('RACK_ENV') { :development }.to_sym
        @logger   = Logger.new($stdout)
        @root     = Pathname.new(File.join(__dir__, '..', '..', '..')).expand_path
        @db       = Sequel.connect(ENV.fetch('DATABASE_URL'))
      end

      def checkout
        @checkout ||= Checkout.new
      end

      def call(env)
        checkout.call(env)
      end

      def init!
        Stripe.api_key = ENV.fetch('STRIPE_KEY')
        self
      end
    end
  end
end
