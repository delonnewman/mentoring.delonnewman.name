# frozen_string_literal: true

module El
  module Application
    # Represents the application state
    class Base
      extend ClassMethods

      def self.init!(env = ENV.fetch('RACK_ENV', 'development').to_sym)
        new(env).init!
      end

      def self.Package
        @package_class ||= Application::Package.create(self)
      end

      def self.Resource
        @resource_class ||= Application::Resource.create(self)
      end

      attr_reader :env, :logger, :root_path, :request, :settings, :loader, :routers

      def initialize(env)
        @env       = env # development, test, production, ci, etc.
        @logger    = Logger.new($stdout, level: log_level)
        @root_path = Pathname.new(self.class.root_path || Dir.pwd)
        @settings  = Settings.new(self)
        @loader    = Loader.new(self)
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

      # Rack interface
      def call(env)
        @request = Rack::Request.new(env)

        # reload! if development?

        # dispatch routes
        routers.each do |router|
          res = router.call(env)
          return res unless res[0] == 404
        end
      end

      def init!
        raise 'An application can only be initialized once' if initialized?

        settings.load!
        loader.load!

        load_resources!
        load_entities!
        load_packages!
        load_routers!

        initialized!

        self
      end

      def initialized?
        !!@initialized
      end

      def repositories
        @repositories ||= {}
      end

      def ensure_repository!(entity_class)
        repositories.fetch(entity_class) do
          raise "No repository for #{entity_class}"
        end
      end

      private

      def initialized!
        @initialized = true
      end

      def load_package!(package)
        method_name = Utils.snakecase(package.name.split('::').last)
        var_name = "@#{method_name}"
        pkg = package.is_a?(Class) ? package : self.class.resolve_class_symbol(package)
        instance = pkg.new(self)

        instance_variable_set(var_name, instance)

        define_singleton_method method_name do
          instance_variable_get(var_name)
        end

        instance
      end

      def load_resource!(resouce)
        load_package!(resouce).tap(&:load!)
      end

      def load_resources!
        self.class.resources.each do |resource|
          logger.info "Loading resource #{resource}..."
          load_resource!(resource)
        end
      end

      def load_packages!
        self.class.packages.each do |pkg|
          logger.info "Loading package #{pkg}..."
          load_package!(pkg)
        end
      end

      def init_repository!(entity_class)
        repositories[entity_class] = entity_class.repository_class.new(
          self,
          database[entity_class.repository_table_name.to_sym],
          entity_class
        )
      end

      def define_repository_accessor!(entity_class, repository)
        method_name = Inflection.plural(Utils.snakecase(entity_class.name.split('::').last))
        var_name = "@#{method_name}"

        instance_variable_set(var_name, repository)

        define_singleton_method method_name do
          instance_variable_get(var_name)
        end
      end

      def load_entity!(entity)
        entity_class = entity.is_a?(Class) ? entity : self.class.resolve_class_symbol(entity)

        define_repository_accessor!(entity_class, init_repository!(entity_class))

        entity_class
      end

      def load_entities!
        self.class.entities.each do |entity|
          logger.info "Loading entity #{entity}..."
          load_entity!(entity)
        end
      end

      def load_routers!
        self.class.routers.each do |router|
          logger.info "Loading router #{router}..."
          @routers ||= []
          @routers << (router.is_a?(Class) ? router : self.class.resolve_class_symbol(router))
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
