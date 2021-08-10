# frozen_string_literal: true
module Drn
  module Framework
    class AdminController
      include Templatable
      include Authenticable

      DEFAULT_OPTIONS = {
        layout: :admin,
        name: 'admin',
        controller_super_class: Controller
      }.freeze

      attr_reader :controllers,
                  :options,
                  :prefix,
                  :app,
                  :canonical_name,
                  :layout,
                  :request

      extend Forwardable
      def_delegators :controllers, :[]
      def_delegators :app, :logger

      def self.build(*entity_classes, **options)
        new(entity_classes, **options).build!
      end

      def initialize(entity_classes, prefix: '/admin', **options)
        @prefix = prefix.freeze
        @options = DEFAULT_OPTIONS.merge(options)
        @canonical_name = @options.delete(:name)
        @layout = @options[:layout]

        @controllers =
          entity_classes
            .reduce({}) do |h, klass|
              c = EntityController.new(klass, **@options)
              h.merge!(c.canonical_name.to_sym => c)
            end
            .freeze
      end

      def build!
        @controllers.each_value(&:build!)
        self
      end

      def routes
        @controllers.each_value.reduce(nil) do |routes, controller|
          controller_routes = controller.routes.to_a
          if routes.nil?
            controller_routes
          else
            routes + controller_routes
          end
        end
      end

      def call(env)
        @app =
          env.fetch('mentoring.app') do
            raise 'mentoring.app key should be set in env before calling a controller'
          end

        @request = Rack::Request.new(env)

        unless current_user.admin?
          res = Rack::Response.new
          res.redirect('/') # TODO: add message to user
          return res.finish
        end

        env['PATH_INFO'] = env['PATH_INFO'].sub(prefix, '')

        if env['PATH_INFO'] == '/' && env['REQUEST_METHOD'] == 'GET'
          content =
            render_template('admin/console', { controllers: controllers })
          [200, Rack::Routable::DEFAULT_HEADERS.dup, [content]]
        else
          res = nil
          @controllers.each_value do |controller|
            res = controller.call(env)
            break if res[0] != 404
          end
          res
        end
      end
    end
  end
end
