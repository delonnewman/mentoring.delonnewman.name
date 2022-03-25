module El
  module Pluggable
    extend Trait

    requires :define_before_processor

    def plugin(plug)
      define_before_processor(plug)

      return unless plug.is_a?(Module) && plug.const_defined?(:InstanceMethods)

      include(plug.const_get(:InstanceMethods))
    end
  end
end
