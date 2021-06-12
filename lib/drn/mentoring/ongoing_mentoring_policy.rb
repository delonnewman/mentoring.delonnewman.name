module Drn
  module Mentoring
    class OngoingMentoringPolicy
      attr_reader :product

      def initialize(product)
        @product = product
      end

      def disabled?(user)
        true
      end
    end
  end
end
