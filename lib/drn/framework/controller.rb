# frozen_string_literal: true

module Drn
  module Framework
    class Controller < Templated
      include Rack::Routable
      include Core

      def json
        @json ||= JSONResponse.new(response)
      end

      def status(status)
        response.tap { |r| r.status = status }
      end

      def render(name = nil, **options)
        return name if name.is_a?(Rack::Response)

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
              res.write content
              res.set_header 'Content-Type', 'application/javascript'
            end
          else
            raise 'No content to render has been specified'
          end
        else
          view = options.delete(:with) || EMPTY_HASH
          response.tap do |res|
            res.write render_template(name, view)
            res.set_header 'Content-Type', 'text/html'
          end
        end
      end

      attr_reader :app

      def initialize(env)
        super(env)
        @app = env['mentoring.app']
      end

      def logger
        app.logger
      end

      def current_user
        app.current_user
      end
    end
  end
end
