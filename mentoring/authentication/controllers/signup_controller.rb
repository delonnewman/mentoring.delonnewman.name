# frozen_string_literal: true

module Mentoring
  module Authentication
    # A controller for the authentiation module
    class SignupController < ApplicationController
      layout :main

      def index
        render :signup
      end

      def create
        data = params.slice(:username, :email)

        app.user_registrations.valid?(data) do |user|
          create_registration_and_notify(user)

          redirect_to routes.dashboard_path
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
