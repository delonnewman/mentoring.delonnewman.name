# frozen_string_literal: true

module Mentoring
  module Main
    # A view object that represents a users dashboard
    class DashboardView < ApplicationView
      include Helpers

      def session_card
        @session_card ||= SessionCardView.new(app, current_user)
      end

      def products
        app.products.products_with_states(user: current_user, mentors: app.users.mentors_not_in_sessions)
      end

      def mentors
        app.users.mentors
      end

      def sessions
        @sessions ||=
          begin
            predicate = current_user.mentor? ? { mentor_id: current_user.id } : { customer_id: current_user.id }
            app.sessions.active_and_recently_ended_sessions_where(predicate)
          end
      end

      def subscribers
        @subscribers ||= app.products.subscribers
      end
    end
  end
end
