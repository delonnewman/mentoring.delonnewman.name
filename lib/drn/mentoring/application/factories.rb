# frozen_string_literal: true
module Drn
  module Mentoring
    class Application
      def products
        Product.repository
      end

      def mentoring_sessions
        MentoringSession.repository
      end

      def users
        User.repository
      end
    end
  end
end
