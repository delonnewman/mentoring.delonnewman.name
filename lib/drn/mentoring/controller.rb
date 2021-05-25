# frozen_string_literal: true
module Drn
  module Mentoring
    class Controller
      include Rack::Routable
      include Utils
      extend Utils

      # delegate all immutable instance methods of Application to "App"
      Application.instance_methods(false).each do |method|
        next if Application::METHODS_NOT_SHARED.include?(method)
        define_method method do |*args|
          Drn::Mentoring.app.send(method, *args)
        end
      end

      class << self
        def template_path
          @template_path ||= Drn::Mentoring.app.root.join('templates', cononical_name)
        end

        def layout_path
          @layout_path ||= Drn::Mentoring.app.root.join('templates', 'layouts', "#{layout}.html.erb")
        end

        def cononical_name
          snakecase(name.split('::').last)
        end

        def path_name
          "lib/#{snakecase(name)}.rb"
        end

        def layout(value = nil)
          @layout = value unless value.nil?
          @layout.nil? ? cononical_name : @layout
        end

        def no_layout!
          layout false
        end
      end

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
              res.write content
              res.set_header 'Content-Type', 'application/javascript'
            end
          else
            raise "No content to render has been specified"
          end
        else
          view = options.delete(:with)
          response.tap do |res|
            res.write render_erb(name, view)
            res.set_header 'Content-Type', 'text/html'
          end
        end
      end

      def params
        request.params
      end

      private

      def template_cache
        @template_cache ||= {}
      end

      def template_content(view, path)
        if Drn::Mentoring.app.env == :production && (cached = template_cache[view])
          cached
        else
          code = Erubi::Engine.new(File.read(path)).src
          template_cache[view] = code if Drn::Mentoring.app.env == :production
          code
        end
      end

      def render_erb(name, __view__)
        __binding__ = binding

        if __view__.is_a?(Hash)
          __data__ = __view__
          __data__.each_pair do |key, value|
            __binding__.local_variable_set(key, value)
          end
        end

        __path__ = self.class.template_path.join("#{name}.html.erb")

        if self.class.layout
          __content__ = eval(template_content(name, __path__), __binding__)
          eval(template_content(:layout, self.class.layout_path), __binding__)
        else
          eval(template_content(name, __path__), __binding__)
        end
      end
    end
  end
end
