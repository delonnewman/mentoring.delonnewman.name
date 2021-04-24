# frozen_string_literal: true
module Drn
  module Mentoring
    class Controller
      include Rack::Routable

      class << self
        def template_path
          @template_path ||= App.root.join('templates', name.split('::').last.downcase)
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
  
        def render_erb(view)
          # TODO: add caching
          eval Erubi::Engine.new(File.read(template_path.join("#{view}.html.erb"))).src
        end
      end
    end
  end
end
