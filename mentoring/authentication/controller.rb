# frozen_string_literal: true

module Mentoring
  module Authentication
    # A controller for the authentiation module
    class Controller < El::Controller
      def signup
        data = params.slice(:username, :email)

        app.user_registrations.valid?(data) do |user|
          create_registration_and_notify(user)

          redirect_to app.routes.dashboard_path
        end

        render :signup, with: { errors: app.UserRegistration.errors(data) }
      end

      def create_registration_and_notify(user)
        app.user_registrations.store!(user)
        app.messenger.signup(user).wait!
      end
    end
  end
end