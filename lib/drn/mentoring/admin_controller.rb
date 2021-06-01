# frozen_string_literal: true
module Drn
  module Mentoring
    class AdminController
      include Templatable
      include Authenticable
      
      DEFAULT_OPTIONS = {
        layout: :admin,
        name: 'admin',
        controller_super_class: Controller
      }.freeze

      attr_reader :controllers, :options, :prefix, :app, :canonical_name, :layout, :request

      extend Forwardable
      def_delegators :controllers, :[]

      def self.build(*entity_classes, **options)
        new(entity_classes, **options).build!.freeze
      end
      
      def initialize(entity_classes, prefix: '/admin', **options)
        @prefix         = prefix.freeze
        @options        = DEFAULT_OPTIONS.merge(options)
        @canonical_name = @options.delete(:name)
        @layout         = @options[:layout]
        
        @controllers = entity_classes.reduce({}) do |h, klass|
          c = EntityController.new(app, klass, **@options)
          h.merge!(c.canonical_name.to_sym => c)
        end.freeze
      end

      def build!
        controllers = @controllers
        @controller = Rack::Builder.app do
          controllers.each_value do |controller|
            controller.build!
            run controller
          end
        end
        
        self
      end

      def freeze
        @controllers.each_value(&:freeze)
        self
      end

      def call(env)
        unless @controller
          raise "This controller has not been built, please call the #build! method"
        end

        @app = env.fetch('mentoring.app') do
          raise "mentoring.app key should be set in env before calling a controller"
        end

        @request = Rack::Request.new(env)

        unless current_user.admin?
          res = Rack::Response.new
          res.redirect('/') # TODO: add message to user
          return res.finish
        end
        
        env['PATH_INFO'] = env['PATH_INFO'].sub(prefix, '')
        
        if env['PATH_INFO'] == '/' && env['REQUEST_METHOD'] == 'GET'
          content = render_template(:index, { controllers: controllers })
          [200, Rack::Routable::DEFAULT_HEADERS.dup, [content]]
        else
          @controller.call(env)
        end
      end
    end
  end
end
