# frozen_string_literal: true

require_relative 'resolved_routes'

module El
  class Controller < Templated
    include Memoize
    extend Pluggable

    attr_reader :router, :request

    def initialize(router, request)
      super()

      @router = router
      @request = self.class.apply_plugins(app, request)

      freeze
    end

    def app
      router.app
    end

    memoize def routes
      ResolvedRoutes.new(request.base_url, router.app.routes)
    end

    memoize def template(name)
      Template[self, template_path(name)]
    end

    def render_template(name, view = EMPTY_HASH)
      template(name)&.call(view)
    end

    def logger
      app.logger
    end

    def response
      router.response
    end

    def params
      request.params
    end

    def json(*args, **kwargs)
      router.json(*args, **kwargs)
    end

    def escape_html(*args)
      CGI.escapeHTML(*args)
    end
    alias h escape_html

    def redirect_to(url)
      r = Rack::Response.new
      r.redirect(url)

      router.halt r.finish
    end

    def url_for(*args)
      request.url_for(*args)
    end

    def render(name = nil, **options)
      return name if name.is_a?(Rack::Response)
      return render_view(name, options) unless name.nil?

      render_special_types(options)
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
        view = name.new(self, request)
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
