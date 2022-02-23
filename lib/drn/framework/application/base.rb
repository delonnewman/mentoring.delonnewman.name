# frozen_string_literal: true

require 'rack/contrib/try_static'

module Drn
  module Framework
    module Application
      # Represents the application state
      class Base
        extend ClassMethods

        attr_reader :env, :logger, :root_path, :request, :settings, :loader

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
          root_path.join(app_name)
        end

        def template_path(*parts, ext: 'html.erb')
          app_path.join('templates', "#{parts.join('/')}.#{ext}")
        end

        def layout_path(name)
          template_path('layouts', name)
        end

        # Rack interface
        def call(env)
          @request = Rack::Request.new(env)

          reload! if development?

          # dispatch routes
        end

        def init!
          raise 'An application can only be initialized once' if initialized?

          settings.load!
          loader.load!

          load_resources!
          load_packages!
          initialized!

          freeze
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
      end
    end
  end
end
