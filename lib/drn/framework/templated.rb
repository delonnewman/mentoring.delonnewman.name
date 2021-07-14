# frozen_string_literal: true
module Drn
  module Framework
    class Templated
      include Utils
      include Templatable

      class << self
        def canonical_name
          Utils.snakecase(name.split('::').last)
        end

        def layout(value = nil)
          @layout = value unless value.nil?
          @layout.nil? ? canonical_name : @layout
        end
      end

      %i[layout canonical_name].each do |method|
        class_eval " def #{method}; self.class.#{method} end "
      end

      def app
        raise ":app method is not implemented for #{self.class}"
      end
    end
  end
end
