# frozen_string_literal: true

module Mentoring
  module Authentication
    # Routes for authenticating and creating user accounts
    class Router < Application.Router()
      namespace '/signup', authenticate: false do
        get  '/', SignupController, :index
        post '/', SignupController, :create
      end

      namespace '/activate', authenticate: false do
        get  '/:id', ActivationController, :show
        post '/:id', ActivationController, :update
      end

      namespace '/login', authenticate: false do
        get  '/', SigninController, :index
        post '/', SigninController, :create
      end

      post '/logout', SigninController, :remove
    end
  end
end
