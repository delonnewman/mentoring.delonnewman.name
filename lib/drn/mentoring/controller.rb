# frozen_string_literal: true
module Drn
  module Mentoring
    class Controller < Templated
      include Rack::Routable

      def status(status)
        response.tap do |r|
          r.status = status
        end
      end
  
      def render(name = nil, **options)
        if name.nil?
          if (content = options.delete(:json))
            response.tap do |res|
              res.write content.to_json
              res.set_header 'Content-Type', 'application/json'
            end
          elsif (content = options.delete(:plain))
            response.tap do |res|
              res.write content
              res.set_header 'Content-Type', 'text/plain'
            end
          elsif (content = options.delete(:js))
            response.tap do |res|
              content = content.to_js if content.respond_to?(:to_js)
              res.write escape_javascript content
              res.set_header 'Content-Type', 'application/javascript'
            end
          else
            raise "No content to render has been specified"
          end
        else
          view = options.delete(:with) || EMPTY_HASH
          response.tap do |res|
            res.write render_template(name, view)
            res.set_header 'Content-Type', 'text/html'
          end
        end
      end

      # delegate all immutable instance methods of Application to @app
      Application.instance_methods(false).each do |method|
        next if Application::METHODS_NOT_SHARED.include?(method)
        define_method method do |*args|
          @app.send(method, *args)
        end
      end

      attr_reader :app

      def initialize(env)
        super(env)
        @app = env['mentoring.app']
      end
    end
  end
end
