# frozen_string_literal: true
module Drn
  module Mentoring
    class Application
      def products
        Product.repository
      end

      def sessions
        Session.repository
      end

      def users
        User.repository
      end
    end
  end
end
