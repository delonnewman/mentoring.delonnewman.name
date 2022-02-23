# frozen_string_literal: true

module Mentoring
  class Product < Drn::Framework::Entity
    # Represents the policy for enabling the current user to select 'Ongoing Mentoring'.
    class OngoingMentoringPolicy
      attr_reader :product

      def initialize(product)
        @product = product
      end

      MAXIMUM_STUDENTS = 3

      # Return true if the user is already subscribed or the mentor
      # is at his maximum number of students.
      def disabled?(user)
        return false unless user

        Mentoring.app.products.product_ids_by_customer(user).include?(product.id)
      end
    end
  end
end
