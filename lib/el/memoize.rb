module El
  module Memoize
    def self.included(base)
      base.extend(ClassMethods)
      base.prepend(InstanceMethods)
    end

    module ClassMethods
      def memoize(method_name)
        alias_method :"#{method_name}_unmemoized", method_name
        define_method method_name do |*args|
          @__memos__[method_name] ||= {}
          @__memos__[method_name][args.hash] ||= send(:"#{method_name}_unmemoized", *args)
        end
      end
    end

    module InstanceMethods
      def initialize(*args)
        @__memos__ = {}
        super
      end
    end
  end
end
