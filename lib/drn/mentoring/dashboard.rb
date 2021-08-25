# frozen_string_literal: true

module Drn
  module Mentoring
    # A view object that represents a users dashboard
    class Dashboard
      require_relative 'session_card'

      attr_reader :app, :user, :session_card

      def initialize(app, user)
        @app = app
        @user = user
        @session_card = SessionCard.new(app, self)
      end

      def products
        app.products.products_and_purchased_by_customer(user)
      end

      def mentors
        app.users.mentors
      end

      def sessions
        if user.mentor?
          app.mentoring_sessions.active_and_recently_ended_sessions_where(mentor_id: user.id)
        else
          app.mentoring_sessions.active_and_recently_ended_sessions_where(customer_id: user.id)
        end
      end

      def subscribers
        app.products.subscribers
      end
    end
  end
end
