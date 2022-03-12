# frozen_string_literal: true

module Mentoring
  module Main
    class SessionCardView
      def initialize(app, user)
        @app = app
        @user = user
      end

      def displayed_user(session)
        mentor = @app.users.default_mentor.nil? ? session.mentor : 'your mentor'
        @user.mentor? ? session.customer : mentor
      end
    end
  end
end
