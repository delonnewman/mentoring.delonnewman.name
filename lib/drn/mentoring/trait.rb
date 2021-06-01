module Drn
  module Mentoring
    module Trait
      def required(*methods)
        @required_methods = methods
      end

      def required_methods
        @required_methods
      end

      def self.included(base)
        required_methods.each do |method|
          unless method_defined?(method)
            raise "#{method} must be defined to use this trait: #{self}"
          end
        end
      end
    end
  end
end
