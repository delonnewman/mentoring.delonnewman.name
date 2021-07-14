# frozen_string_literal: true

module Drn
  module Mentoring
    # Manage email communication for the application
    class ApplicationMessenger < Framework::Mailer
      layout :mailer

      def signup(user)
        mail :signup, { user: user },
             to: user,
             subject: 'Thank you for giving us a try! Please complete your registration.'
      end

      def new_session(session)
        mail :new_session, { session: session },
             to: session.mentor,
             subject: "You've got a new session with #{session.customer}"
      end

      private

      def session_url(session)
        "https://#{app.settings['DOMAIN']}/activate/#{session.id}"
      end

      def activation_url(user)
        "https://#{app.settings['DOMAIN']}/activate/#{user.id}?key=#{user.activation_key}"
      end
    end
  end
end
