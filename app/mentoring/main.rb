# frozen_string_literal: true

module Mentoring
  # Routes for the landing page of the site
  class Main < Drn::Framework::Controller
    include MainHelpers
    include Drn::Framework::TimeUtils

    static '/' => 'public'

    mount '/checkout', Checkout
    mount '/session', MentoringSessions
    mount '/products', Products

    mount '/admin',
          Drn::Framework::AdminController.build(
            User,
            UserRegistration,
            UserRole,
            Product,
            ProductRate,
            MentoringSession
          )

    get '/', authenticate: false do
      products = app.products.products_with_states(user: current_user, mentors: app.users.mentors_not_in_sessions)

      render :index, with: {
        products: products,
        mentor: app.default_mentor
      }
    end

    get '/dashboard' do
      render :dashboard, with: Dashboard.new(app, current_user)
    end

    get '/state.js', authenticate: false do
      state = { authenticated: authenticated? }

      render js: "Mentoring = {}; Mentoring.state = #{state.to_json}"
    end

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
      elsif (errors = User.errors(data)).empty?
        User[data].tap do |user|
          logger.info "Storing user: #{user.inspect}"
          app.users.store!(user)
          current_user!(user)
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
        current_user! user
        redirect_to ref
      else
        status 401
        render :login
      end
    end

    post '/logout' do
      logout!

      if request.content_type == 'application/javascript'
        render json: { redirect: app.routes.root_path }
      else
        redirect_to app.routes.root_path
      end
    end

    def error(e)
      logger.error e.message
      e.backtrace.each { |trace| logger.error "  #{trace}" }

      render :error
    end
  end
end
