module Mentoring
  module Main
    class IndexView < BaseView
      include Helpers

      def mentor
        app.users.default_mentor
      end

      def products
        app.products.products_with_states(user: current_user, mentors: app.users.mentors_not_in_sessions)
      end
    end
  end
end
