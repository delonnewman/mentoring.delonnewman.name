# frozen_string_literal: true

module El
  module Application
    class Router < Templated
      include Dependency
      include Routable

      def self.add_to!(app_class)
        super(app_class)

        parts = name.split('::')
        name = Utils.underscore(parts[parts.length - 2]).to_sym
        app_class.add_dependency!(name, self, kind: :routers)
      end

      def self.init_app!(app, router_class)
        router = router_class.new(app)

        router.extend(Authenticable::RouterMethods) if app.is_a?(Authenticable)
        app.routes << router

        router
      end

      def self.canonical_name
        parts = name.split('::')
        ident = parts.last == 'Router' ? parts[parts.length - 2] : parts.last
        Utils.underscore(ident)
      end

      attr_reader :app

      def initialize(app)
        super()

        @app = app
      end

      def logger
        app.logger
      end

      def json
        @json ||= JSONResponse.new(response)
      end

      def status(status)
        response.tap { |r| r.status = status }
      end

      def render(name = nil, **options)
        return name if name.is_a?(Rack::Response)
        return render_hash_view(name, options) unless name.nil?

        render_special_types(options)
      end

      protected

      def url_for(path)
        [request.path, path].join('/')
      end

      private

      def render_special_types(options)
        if (content = options.delete(:json))
          render_json(content)
        elsif (content = options.delete(:plain))
          render_plain(content)
        elsif (content = options.delete(:js))
          render_js(content)
        else
          raise 'No content to render has been specified'
        end
      end

      def render_json(content)
        response.tap do |res|
          res.write content.to_json
          res.set_header 'Content-Type', 'application/json'
        end
      end

      def render_plain(content)
        response.tap do |res|
          res.write content
          res.set_header 'Content-Type', 'text/plain'
        end
      end

      def render_js(content)
        response.tap do |res|
          content = content.to_js if content.respond_to?(:to_js)
          res.write content
          res.set_header 'Content-Type', 'application/javascript'
        end
      end

      def render_hash_view(name, options)
        view = options.delete(:with) || EMPTY_HASH
        response.tap do |res|
          res.write render_template(name, view)
          res.set_header 'Content-Type', 'text/html'
        end
      end
    end
  end
end
