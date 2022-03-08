module El
  module Application
    class LiveReload
      include Servicable

      attr_reader :app

      def initialize(app)
        @app = app
      end

      def load!
        require 'rack-livereload'
        app.use Rack::LiveReload
      end

      def unload!; end
    end
  end
end
