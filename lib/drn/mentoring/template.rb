module Drn
  module Mentoring
    class Template
      include Invokable
      include TemplateHelpers
      include Utils

      extend Forwardable
      def_delegators :@templated, :params, :app, :request

      attr_reader :path, :layout

      class << self
        def path(name, templated)
          if name.is_a?(Symbol) || !name.include?('/')
            templated.app.template_path(templated.canonical_name, name)
          else
            return Pathname.new(name) if File.exist?(name)

            templated.app.template_path(name)
          end
        end

        def layout_path(templated)
          templated.layout && templated.app.layout_path(templated.layout)
        end

        def [](templated, name)
          tmpl = new(templated, path(name, templated), layout_path(templated))

          templated.app.env == :production ? tmpl.memoize : tmpl
        end
      end

      def initialize(templated, path, layout)
        @templated = templated
        @app = templated.app
        @path = path
        @layout = Template.new(templated, layout, nil) if layout
      end

      def method_missing(method, *args, **kwargs)
        @templated.send(method, *args, **kwargs)
      end

      def respond_to?(method, include_all = false)
        super || @templated.respond_to?(method, include_all)
      end

      def call(view)
        define_singleton_method(:view) { view }

        if view.is_a?(Hash)
          define_singleton_method(:locals) { view }
          view.each_pair { |key, value| define_singleton_method(key) { value } }
        end

        content = eval(code, binding, path.to_s)

        if @layout
          @layout.call(view.merge(__content__: content, view: view))
        else
          content
        end
      end

      def code
        if app.env == :production && @code
          @code
        else
          @code = Erubi::Engine.new(path.read).src
        end
      end
    end
  end
end
