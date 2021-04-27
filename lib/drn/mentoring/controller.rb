# frozen_string_literal: true
module Drn
  module Mentoring
    class Controller
      include Rack::Routable
      extend Utils

      # delegate all immutable instance methods of Application to "App"
      Application.instance_methods(false).each do |method|
        next if Application::METHODS_NOT_SHARED.include?(method)
        define_singleton_method method do |*args|
          App.send(method, *args)
        end
      end

      class << self
        def call(env)
          
        end

        def template_path
          @template_path ||= root.join('templates', cononical_name)
        end

        def layout_path
          @layout_path ||= root.join('templates', 'layouts', "#{layout}.html.erb")
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
  
        def render(name = nil, **options)
          if name.nil?
            if (content = options.delete(:json))
              opts = options.merge(headers: { 'Content-Type' => 'application/json' })
              response content.to_json, **opts
            elsif (content = options.delete(:plain))
              opts = options.merge(headers: { 'Content-Type' => 'text/plain' })
              response content.to_s, **opts
            else
              raise "No content to render has been specified"
            end
          else
            view = options.delete(:with)
            response render_erb(name, view), **options
          end
        end

        private

        def template_cache
          @template_cache ||= {}
        end

        def template_content(view, path)
          if App.env == :production && (cached = template_cache[view])
            cached
          else
            code = Erubi::Engine.new(File.read(path)).src
            template_cache[view] = code if App.env == :production
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

          __path__ = template_path.join("#{name}.html.erb")

          if layout
            __content__ = eval(template_content(name, __path__), __binding__)
            eval(template_content(:layout, layout_path), __binding__)
          else
            eval(template_content(name, __path__), __binding__)
          end
        end
      end
    end
  end
end
