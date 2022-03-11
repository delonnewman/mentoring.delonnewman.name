# frozen_string_literal: true

module El
  module Application
    class Router < Templated
      include Dependency
      include Routable

      # Common Media Types
      # (see https://developer.mozilla.org/en-US/docs/Web/HTTP/Basics_of_HTTP/MIME_types/Common_types, and
      #  https://www.iana.org/assignments/media-types/media-types.xhtml)
      media_type :plain,      'text/plain'
      media_type :csv,        'test/csv'
      media_type :ics,        'text/calendar'
      media_type :pdf,        'application/pdf'
      media_type :epub,       'application/epub+zip'
      media_type :rtf,        'application/rtf'

      media_type :html,       'text/html'
      media_type :css,        'text/css'
      media_type :javascript, 'text/javascript'
      media_type :json,       'application/json'
      media_type :jsonld,     'application/ld+json'
      media_type :xml,        'application/xml', 'text/xml'
      media_type :xhtml,      'application/xhtml'
      media_type :php,        'application/x-httpd-php'
      media_type :atom,       'application/atom+xml'
      media_type :rdf,        'application/rdf+xml'
      media_type :rss,        'application/rss+xml'

      media_type :gz,         'application/gzip'
      media_type :bz,         'application/x-bzip'
      media_type :bz2,        'application/x-bzip2'

      media_type :jpeg,       'image/jpeg'
      media_type :gif,        'image/gif'
      media_type :png,        'image/png'
      media_type :image,      'image/tiff'
      media_type :svg,        'image/svg+xml'

      def self.add_to!(app_class)
        super(app_class)

        parts = name.split('::')
        name = StringUtils.underscore(parts[parts.length - 2]).to_sym
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
        StringUtils.underscore(ident)
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
        return render_view(name, options) unless name.nil?

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

      def render_view(name, options)
        if name.is_a?(Class)
          view = name.new(self)
          name = name.template_name
        else
          view = options.delete(:with) || EMPTY_HASH
        end

        response.tap do |res|
          res.write render_template(name, view)
          res.set_header 'Content-Type', 'text/html'
        end
      end
    end
  end
end
