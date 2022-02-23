module Drn
  module Framework
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
            templated.app.app_path.join(templated.app.app_name, templated.canonical_name, "#{name}.html.erb")
          else
            return Pathname.new(name) if File.exist?(name)

            templated.app.app_path.join(templated.app.app_name, "#{name}.html.erb")
          end
        end

        def layout_path(templated)
          templated.layout && templated.app.app_path.join(templated.app.app_name, 'layouts',
                                                          "#{templated.layout}.html.erb")
        end

        def [](templated, name)
          tmpl = new(templated, path(name, templated), layout_path(templated))

          templated.app.production? ? tmpl.memoize : tmpl
        end
      end

      def initialize(templated, path, layout)
        @templated = templated
        @app = templated.app
        @path = path
        @layout = Template.new(templated, layout, nil) if layout
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

      def call(view)
        define_singleton_method(:view) { view }

        if view.is_a?(Hash)
          define_singleton_method(:locals) { view }
          view.each_pair { |key, value| define_singleton_method(key) { value } }
        end

        content = eval(code, binding, path.to_s)

        if @layout
          @layout.call(if view.is_a?(Hash)
                         view.merge(__content__: content,
                                    view: view)
                       else
                         { __content__: content, view: view }
                       end)
        else
          content
        end
      end

      def code
        return @code if app.env == :production && @code

        @code = Erubi::Engine.new(path.read).src
      end
    end
  end
end
