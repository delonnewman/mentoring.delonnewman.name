module Drn
  module Mentoring
    class Product < Framework::Entity
      # Represents the policy for enabling the current user to select 'Ongoing Mentoring'.
      class OngoingMentoringPolicy
        attr_reader :product

        def initialize(product)
          @product = product
        end

        MAXIMUM_STUDENTS = 3

        def app
          Drn::Mentoring.app
        end

        # Return true if the user is already subscribed or the mentor
        # is at his maximum number of students.
        def disabled?(user)
          return false unless user

          app.products.ids_of_customer(user).include?(product.id)
        end
      end
    end
  end
end
