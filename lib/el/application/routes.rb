module El
  module Application
    class Routes
      attr_reader :app, :helpers

      def initialize(app)
        @app = app
        @routers = []
        @helpers = {}
      end

      def <<(router)
        @routers << router
        router.routes.route_helper_methods.each do |name, p|
          @helpers[name] = p
        end
      end

      def [](helper)
        @helpers[helper]
      end

      def has?(helper)
        @helpers.key?(helper)
      end

      def route_helpers
        @helpers.keys
      end
    end
  end
end
