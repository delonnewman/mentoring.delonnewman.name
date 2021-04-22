module Drn
  module Mentoring
    class Controller
      include Rack::Routable

      class << self
        def template_path
          @template_path ||= App.root.join('templates', name.split('::').last.downcase)
        end
  
        def render(view)
          if view.respond_to?(:call)
            view.call
          else
            render_erb(view)
          end
        end
  
        private
  
        def render_erb(view)
          body = eval(Erubi::Engine.new(File.read(template_path.join("#{view}.html.erb"))).src)
  
          { status: 200,
            'headers' => { 'Content-Type': 'text/html' },
            body: StringIO.new(body) }
        end
      end
    end
  end
end
