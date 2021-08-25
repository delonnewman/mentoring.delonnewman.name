module Drn
  module Mentoring
    # A view object that represents a users dashboard
    class Dashboard
      attr_reader :app, :user

      def initialize(app, user)
        @app = app
        @user = user
      end

      def products
        app.products.products_and_purchased_by_customer(user)
      end

      def mentors
        app.users.mentors
      end

      def sessions
        app.mentoring_sessions.active_sessions_for_user(user)
      end

      def subscribers
        app.products.subscribers
      end
    end
  end
end
