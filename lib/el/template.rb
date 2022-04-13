# frozen_string_literal: true

module El
  class Template
    include Invokable
    include TemplateHelpers
    include Utils

    extend Forwardable
    def_delegators :@templated, :params, :app, :request

    attr_reader :path, :layout

    class << self
      def layout_path(templated)
        templated.layout && templated.app.app_path.join('layouts', "#{templated.layout}.html.erb")
      end

      def [](templated, path)
        tmpl = new(templated, path, layout_path(templated))

        templated.app.settings[:template_caching] ? tmpl.memoize : tmpl
      end
    end

    def initialize(templated, path, layout)
      @templated = templated
      @app       = templated.app
      @path      = path
      @layout    = Template.new(templated, layout, nil) if layout
    end

    def render(*args)
      @templated.render_template(*args)
    end

    def include_file(path)
      @app.root.join(path).read
    end

    def method_missing(method, *args, **kwargs)
      @templated.send(method, *args, **kwargs)
    end

    def respond_to_missing?(method)
      super || @templated.respond_to?(method)
    end

    def code
      return @code if app.settings[:template_caching] && @code

      @code = Erubi::Engine.new(path.read).src
    end

    def call(view)
      content = if view.is_a?(Hash)
                  eval_hash_view(view, binding)
                else
                  view.render(code, path.to_s)
                end

      return content unless @layout

      @layout.call(layout_arguments(content, view))
    end

    private

    def eval_hash_view(view, scope)
      scope.local_variable_set(:view, view)
      view.each_pair { |key, value| scope.local_variable_set(key, value) }
      scope.eval(code, path.to_s)
    end

    def layout_arguments(content, view)
      if view.is_a?(Hash)
        view.merge(__content__: content, view: view)
      else
        { __content__: content, view: view }
      end
    end
  end
end
