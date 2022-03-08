# frozen_string_literal: true

module El
  class Router < Templated
    include Rack::Routable

    attr_reader :app

    def initialize(app)
      super()

      @app = app
    end

    def logger
      app.logger
    end

    def current_user
      app.current_user
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
      end.finish
    end

    def render_plain(content)
      response.tap do |res|
        res.write content
        res.set_header 'Content-Type', 'text/plain'
      end.finish
    end

    def render_js(content)
      response.tap do |res|
        content = content.to_js if content.respond_to?(:to_js)
        res.write content
        res.set_header 'Content-Type', 'application/javascript'
      end.finish
    end

    def render_hash_view(name, options)
      view = options.delete(:with) || EMPTY_HASH
      response.tap do |res|
        res.write render_template(name, view)
        res.set_header 'Content-Type', 'text/html'
      end.finish
    end
  end
end
