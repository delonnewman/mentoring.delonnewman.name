# frozen_string_literal: true

require_relative 'resolved_routes'

module El
  class Controller
    include Memoize
    include Templating

    extend Pluggable
    extend Forwardable

    class << self
      alias call_without_processors new
      alias call new

      def call_with_processors(router, request)
        request = apply_before_processors(router.app, request) || request
        new(router, request)
      end

      def apply_before_processors(app, request)
        return request unless (procs = processors[:before])

        procs.reduce(request) do |req, p|
          p.call(app, req) || req
        end
      end

      def processors
        procs = @processors ||= {}

        procs.merge!(superclass.processors) if superclass.respond_to?(:processors)

        procs
      end

      def freeze
        processors.freeze
        self
      end

      # Class DSL methods

      def before(callable = nil, &block)
        processors[:before] ||= []
        processors[:before] << callable || block
        class << self
          undef_method :call
          alias_method :call, :call_with_processors
        end
      end
      alias define_before_processor before

      def around(action, callable = nil, &block)
        processors[:around] ||= {}
        processors[:around][action] ||= []
        processors[:around][action] << callable || block
        undef_method :call
        alias_method :call, :call_with_processors
      end
      alias define_around_processor around

      def after(action, callable = nil, &block)
        processors[:after] ||= {}
        processors[:after][action] ||= []
        processors[:after][action] << callable || block
        undef_method :call
        alias_method :call, :call_with_processors
      end
      alias define_after_processor after
    end

    attr_reader :router, :request

    def_delegator 'self.class', :processors

    def initialize(router, request)
      @router = router
      @request = request
      Memoize.init_memoize_state!(self)

      freeze
    end

    def apply_around_processors(action)
      procs = processors.fetch(:around, EMPTY_HASH).fetch(action, nil)
      return request unless procs

      procs.reduce(request) do |req, p|
        p.call(self, req) || req
      end
    end

    def apply_after_processors(action, response)
      procs = processors.fetch(:around, EMPTY_HASH).fetch(action, nil)
      return request unless procs

      procs.reduce(response) do |res, p|
        p.call(self, res) || res
      end
    end

    def call_without_processors(action)
      public_send(action)
    end
    alias call call_without_processors

    def call_with_processors(action)
      @request = apply_around_processors(action)
      res = public_send(action)
      apply_after_processors(action, res)
    end

    def app
      router.app
    end

    protected

    # Instance DSL Methods

    def_delegators :router, :app, :response, :json
    def_delegators :request, :params, :url_for
    def_delegators :app, :logger

    memoize def routes
      ResolvedRoutes.new(request.base_url, router.app.routes)
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
        res.write templates.render_template(name, view)
        res.set_header 'Content-Type', 'text/html'
      end
    end
  end
end
