module El
  module Application
    class Routes
      include Enumerable

      attr_reader :app

      def initialize(app)
        @app = app
        @routers = []
        @helper_methods = {}
      end

      def <<(router)
        @routers << router
        router.routes.route_helper_methods.each do |method|
          @helper_methods[method] = router
        end
      end

      def [](path_method)
        @helper_methods[path_method]
      end

      def has?(path_method)
        @helper_methods.key?(path_method)
      end

      def route_helper_methods
        @helper_methods.keys
      end

      def each(&block)
        @routers.each(&block)
      end

      def method_missing(method, *args)
        router = @helper_methods[method]
        raise NoMethodError, "undefined method `#{method} for #{self}:#{self.class}" unless router

        return router.routes.public_send(method, app.request&.base_url, *args) if method.name.end_with?('_url')

        router.routes.public_send(method, *args)
      end

      def respond_to_missing?(method, _include_all)
        @path_methods.key?(method)
      end
    end
  end
end
