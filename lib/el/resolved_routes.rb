# frozen_string_literal: true

module El
  # Application routes resolved to a base url (required for url route helpers)
  class ResolvedRoutes
    attr_reader :base_url, :routes

    def initialize(base_url, routes)
      @base_url = base_url
      @routes = routes
    end

    def method_missing(method, *args)
      helper = routes.helpers[method]
      raise NoMethodError, "undefined method `#{method} for #{self}:#{self.class}" unless helper

      return instance_exec(base_url, *args, &helper) if method.name.end_with?('_url')

      instance_exec(*args, &helper)
    end

    def respond_to_missing?(method, _include_all)
      routes.helpers.key?(method)
    end
  end
end
