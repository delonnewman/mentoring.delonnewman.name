module El
  module Pluggable
    def plugin(plug, **options)
      @plugins ||= []
      @plugins << [plug, options]

      return unless plug.is_a?(Module) && plug.const_defined?(:InstanceMethods)

      include(plug.const_get(:InstanceMethods))
    end

    def plugins
      plugins = []

      plugins += superclass.plugins if superclass.respond_to?(:plugins)
      plugins += @plugins if @plugins

      plugins
    end

    def apply_plugins(app, request)
      plugins.reduce(request) do |req, (plug, opts)|
        plug.call(app, req, opts)
      end
    end
  end
end
