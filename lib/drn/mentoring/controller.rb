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
        def template_path
          @template_path ||= App.root.join('templates', camelcase(name.split('::').last.downcase))
        end
  
        def render(view = nil, **options)
          if view.respond_to?(:call)
            response view.call, **options
          elsif view.nil?
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
            response render_erb(view), **options
          end
        end

        private

        def template_cache
          @template_cache ||= {}
        end
  
        def render_erb(view)
          template_cache[view] ||= Erubi::Engine.new(File.read(template_path.join("#{view}.html.erb"))).src

          eval template_cache[view]
        end
      end
    end
  end
end
