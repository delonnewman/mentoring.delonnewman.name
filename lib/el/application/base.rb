# frozen_string_literal: true

module El
  module Application
    # Represents the application state
    class Base
      extend ClassMethods

      def self.init!(env = ENV.fetch('RACK_ENV', 'development').to_sym)
        new(env).init!
      end

      def self.with_only_settings(env = ENV.fetch('RACK_ENV', 'development').to_sym)
        new(env).tap do |app|
          app.settings.load!
        end
      end

      ClassMethods::DEPENDENCY_KINDS.each do |kind|
        define_singleton_method kind do
          dependencies.fetch(kind)
        end

        define_method kind do
          dependencies.fetch(kind)
        end
      end

      attr_reader :env, :logger, :root_path, :request, :settings, :loader, :dependencies, :server

      def initialize(env)
        @env          = env # development, test, production, ci, etc.
        @logger       = Logger.new($stdout, level: log_level)
        @root_path    = Pathname.new(self.class.root_path || Dir.pwd)
        @settings     = Settings.new(self)
        @loader       = Loader.new(self)
        @dependencies = ClassMethods::DEPENDENCY_KINDS.reduce({}) { |h, kind| h.merge(kind => {}) }
      end

      def reload!
        settings.tap(&:unload!).load!
        loader.reload!
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

      %i[production development test ci].each do |env|
        define_method :"#{env}?" do
          self.env == env
        end
      end

      def lib_path
        root_path.join('lib', app_name)
      end

      def app_name
        parts = self.class.name.split('::')
        Utils.underscore(parts[parts.length - 2])
      end

      def app_path
        root_path.join(app_name)
      end

      DEFAULT_RESPONSE = [404, {}, ['Not Found']].freeze
      private_constant :DEFAULT_RESPONSE

      # Rack interface
      def call(env)
        @request = Rack::Request.new(env)

        reload! if development? && initialized?

        # dispatch routes
        routers.each do |_name, router|
          res = router.call(env)
          return res unless res[0] == 404
        end

        DEFAULT_RESPONSE
      end

      def run!
        init! unless initialized?

        options = { environment: env.name, DocumentRoot: root_path.join('public'), Port: 3000 }

        @server = nil
        Thread.new do
          Rack::Handler::WEBrick.run(self, **options) do |s|
            @server = s
          end
        end

        @running = true
      end

      def running?
        @running
      end

      def stop!
        return unless running?

        server.shutdown
      end

      def init!
        raise 'An application can only be initialized once' if initialized?

        settings.load!
        loader.load!
        initialize_dependencies!

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

      def initialize_dependencies!
        ClassMethods::DEPENDENCY_KINDS.each do |kind|
          self.class.dependencies[kind].each_with_object(dependencies[kind]) do |(name, opts), deps|
            if opts[:init]
              deps.merge!(name => opts[:object].init_app!(self, opts[:object]))
            else
              deps.merge!(name => opts[:object])
            end
          end
        end
      end

      def init_filewatcher!
        watcher = Filewatcher.new([lib_path, app_path])
        Thread.new(watcher) do |w| # TODO: use a fiber instead
          w.watch do |filename|
            logger.info "Changes found in #{filename}. Reloading..."
            reload!
          end
        end
      end
    end
  end
end
