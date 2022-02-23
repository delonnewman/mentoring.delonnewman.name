# frozen_string_literal: true

require 'rack/contrib/try_static'

module Drn
  module Framework
    module Application
      # Represents the application state
      class Base
        extend ClassMethods

        attr_reader :env, :logger, :root_path, :session_secret, :settings, :request

        def initialize(env)
          @env = env
          @logger = Logger.new($stdout, level: log_level)
          @root_path = self.class.root_path || Pathname.pwd
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

        def routes
          Main.routes
        end

        # Rack interface
        def call(env)
          env['mentoring.app'] = self

          @request = Rack::Request.new(env)

          Main.rack.call(env)
        end

        def load_package!(package)
          method_name = Utils.snakecase(package.name.split('::').last)
          var_name = "@#{method_name}"
          instance = package.new(self)

          instance_variable_set(var_name, instance)

          define_singleton_method method_name do
            instance_variable_get(var_name)
          end

          instance
        end

        def load_resource!(resouce)
          load_package!(resouce).tap(&:load!)
        end

        def init!
          raise 'An application can only be initialized once' if initialized?

          self.class.resources.each do |resource|
            load_resource!(resource)
          end

          self.class.packages.each do |pkg|
            load_package!(pkg)
          end

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
      end
    end
  end
end
