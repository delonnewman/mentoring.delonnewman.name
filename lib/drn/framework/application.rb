# frozen_string_literal: true
require 'rack/contrib/try_static'

module Drn
  module Framework
    # Represents the application state
    class Application < Module
      attr_reader :env, :logger
      attr_reader :entity_classes, :component_classes, :controller_classes

      def self.init(env, &block)
        app = new(env)
        block.call(app) if block
        app
      end

      def initialize(env)
        super()

        @env = env
        @logger = Logger.new($stdout, level: log_level)
        @root_path = Pathname.new(File.join(__dir__, '..', '..', '..')).expand_path

        @base_entity_class = _subclass_of(Entity)
        @base_component_class = _subclass_of(Component)
      end

      private

      def _subclass_of(base)
        klass = Class.new(base)
        klass.class_variable_set(:'@@app', self)
        klass.class_eval <<~CODE, __FILE__, __LINE__ + 1
          def self.app
            @@app
          end

          protected

          def app
            @@app
          end
        CODE

        class_name = base.name.split('::').last

        self.class.define_method class_name do
          unless instance_variable_defined?(:"@#{class_name}_classes")
            instance_variable_set(:"@#{class_name.downcase}_classes", [])
          end

          klass = Class.new(instance_variable_get(:"@base_#{class_name.downcase}_class"))
          instance_variable_get(:"@#{class_name.downcase}_classes") << klass

          klass
        end

        klass
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
