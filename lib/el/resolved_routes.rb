module El
  class ResolvedRoutes
    attr_reader :base_url, :routes

    def initialize(base_url, routes)
      @base_url = base_url
      @routes = routes
    end

    def method_missing(method, *args)
      helper = routes.helpers[method]
      raise NoMethodError, "undefined method `#{method} for #{self}:#{self.class}" unless helper

      return helper.call(request.base_url, *args) if method.name.end_with?('_url')

      helper.call(*args)
    end

    def respond_to_missing?(method, _include_all)
      routes.helpers.key?(method)
    end
  end
end
