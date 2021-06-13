module Drn
  module Mentoring
    class OngoingMentoringPolicy
      attr_reader :product

      def initialize(product:)
        @product = product
      end

      MAXIMUM_STUDENTS = 3
      
      # Return true if the user is already subscribed or the mentor
      # is at his maximum number of students.
      def disabled?(user)
        true
      end
    end
  end
end
