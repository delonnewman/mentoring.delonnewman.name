# frozen_string_literal: true

module Mentoring
  module Sessions
    # Manage email communication for the application
    class Messenger < El::MailController
      layout :mailer

      def new_session(session)
        mail :new_session, { session: session },
             to: session.mentor,
             subject: "You've got a new session with #{session.customer}"
      end

      private

      def session_url(session)
        "https://#{app.settings['DOMAIN']}/session/#{session.id}"
      end
    end
  end
end
