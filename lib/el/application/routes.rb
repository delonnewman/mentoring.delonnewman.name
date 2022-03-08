module El
  module Application
    class Routes
      def initialize
        @routers = []
        @path_methods = {}
      end

      def <<(router)
        @routers << router
        router.routes.route_path_methods.each do |method|
          @path_methods[method] = router
        end
      end

      def path_methods
        @path_methods.keys
      end

      def method_missing(method, *_args)
        router = @path_methods[method]
        return router.routes.public_send(method) if router

        raise NoMethodError, "undefined method `#{method} for #{self}:#{self.class}"
      end

      def respond_to_missing?(method, _include_all)
        @path_methods.key?(method)
      end
    end
  end
end