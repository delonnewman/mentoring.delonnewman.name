# frozen_string_literal: true

module Mentoring
  module Authentication
    # Routes for authenticating and creating user accounts
    class Router < Application.Router()
      layout :main

      get '/signup', authenticate: false do
        render :signup
      end

      post '/signup', authenticate: false do
        logger.info "PARAMS: #{params.inspect}"

        data = params.slice('username', 'email').transform_keys(&:to_sym)

        # TODO: move validation to Repository
        if (errors = UserRegistration.errors(data)).empty?
          UserRegistration[data].tap do |user|
            logger.info "Storing user: #{user.inspect}"
            app.user_registrations.store!(user)
            app.messenger.signup(user).wait!
          end

          redirect_to app.routes.dashboard_path
        else
          render :signup, with: { errors: errors }
        end
      end

      get '/activate/:id', authenticate: false do
        if (reg = app.user_registrations.find_active_by_id_and_key(params[:id], params['key']))
          render :account_activated, with: { registration: reg }
        else
          render :activation_invalid
        end
      end

      post '/activate/:id', authenticate: false do
        data = params.slice('displayname', 'username', 'email', 'password')
                     .merge(role: 'customer')
                     .transform_keys(&:to_sym)

        logger.info "Form data: #{data.inspect}"

        if (reg = app.user_registrations.find_active_by_id_and_key(params[:id], params['key'])).nil?
          render :activation_invalid
        elsif User.errors(data).empty?
          User[data].tap do |user|
            logger.info "Storing user: #{user.inspect}"
            app.users.store!(user)
            self.current_user = user
          end
          redirect_to app.routes.login_path
        else
          render :account_activated, { registration: reg }
        end
      end

      get '/login' do
        render :login
      end

      post '/login' do
        user = app.users.find_user_and_authenticate(username: params['username'], password: params['password'])

        ref = params['ref'].blank? ? app.routes.dashboard_path : params['ref']

        if user
          self.current_user = user
          redirect_to ref
        else
          status 401
          render :login
        end
      end

      post '/logout' do
        app.logout!

        if request.content_type == 'application/javascript'
          render json: { redirect: app.routes.root_path }
        else
          redirect_to app.routes.root_path
        end
      end
    end
  end
end
