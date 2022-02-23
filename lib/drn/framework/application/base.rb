# frozen_string_literal: true

# rubocop: disable Metrics/ClassLength

module Drn
  module Framework
    module Application
      # Represents the application state
      class Base
        extend ClassMethods

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
          root_path.join('lib')
        end

        def app_name
          parts = self.class.name.split('::')
          Utils.snakecase(parts[parts.length - 2])
        end

        def app_path
          root_path.join('app')
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

        def load_entity!(entity)
          entity_class = entity.is_a?(Class) ? entity : self.class.resolve_class_symbol(entity)
          repository = entity_class.repository_class.new(
            self,
            database[entity_class.repository_table_name.to_sym],
            entity_class
          )

          method_name = Inflection.plural(Utils.snakecase(entity_class.name.split('::').last))
          var_name = "@#{method_name}"

          instance_variable_set(var_name, repository)

          define_singleton_method method_name do
            instance_variable_get(var_name)
          end

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
        Thread.new(watcher) do |w|
          w.watch do |filename|
            logger.info "Changes found in #{filename}. Reloading..."
            reload!
          end
        end
      end
    end
  end
end
