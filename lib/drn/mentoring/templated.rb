# frozen_string_literal: true
module Drn
  module Mentoring
    class Templated
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
        code = %{ def #{method}; self.class.#{method} end }
        class_eval code
      end
      
      def app
        raise ":app method is not implemented for #{self.class}"
      end
    end
  end
end
