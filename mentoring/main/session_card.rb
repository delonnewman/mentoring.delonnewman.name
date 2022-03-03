# frozen_string_literal: true

module Mentoring
  module Main
    class SessionCard
      def initialize(app, dashboard)
        @app = app
        @dashboard = dashboard
      end

      def displayed_user(session)
        mentor = @app.default_mentor.nil? ? session.mentor : 'your mentor'
        @dashboard.user.mentor? ? session.customer : mentor
      end
    end
  end
end
