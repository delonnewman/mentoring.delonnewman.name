# frozen_string_literal: true

module Mentoring
  # A resource for loading Mailjet configuration
  class Mailings < Application.Service()
    advised_by El::Messenging, delegating: %i[deliver! mail]

    start do
      ::Mailjet.configure do |config|
        config.api_key = app.settings[:mailjet_api_key]
        config.secret_key = app.settings[:mailjet_secret_key]
        config.default_from = 'contact@delonnewman.name'
        config.api_version = 'v3.1'
      end
    end

    def new_session(session)
      mail :new_session, { session: session },
           to: session.mentor,
           subject: "You've got a new session with #{session.customer}"
    end
  end
end
