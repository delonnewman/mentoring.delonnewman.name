# frozen_string_literal: true

module Mentoring
  # Manage email communication regarding mentoring sessions
  class SessionMessenger < Drn::Framework::Mailer
    layout :mailer

    def new_session(session)
      mail :signup, { session: session },
           to: session.mentor,
           subject: "You've got a new session with #{session.customer}"
    end

    private

    def session_url(session)
      "https://#{app.settings['DOMAIN']}/activate/#{session.id}"
    end
  end
end
