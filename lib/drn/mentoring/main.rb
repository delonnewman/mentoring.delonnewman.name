# frozen_string_literal: true
module Drn
  module Mentoring
    class Main < Controller
      include Authenticable
      
      use Rack::Session::Cookie, secret: Mentoring.app.session_secret
      #use Rack::MiniProfiler

      static '/' => 'public'
      
      mount '/checkout', Checkout
      mount '/session',  MentoringSessions

      mount '/admin', AdminController.build(
              User, UserRegistration, UserRole, Product, ProductRate,
              MentoringSession, include: Authenticable)

      get '/', authenticate: false do
        render :index
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

        if (errors = UserRegistration.errors(data)).empty?
          UserRegistration[data].tap do |user|
            logger.info "Storing user: #{user.inspect}"
            user_registrations.store!(user)
            account_messenger.signup(user).wait!
          end
          redirect_to '/'
        else
          render :signup, with: { errors: errors }
        end
      end

      get '/activate/:id', authenticate: false do
        if (reg = user_registrations.find_active_by_id_and_key(params[:id], params['key']))
          render :account_activated, with: { registration: reg }
        else
          render :activation_invalid
        end
      end

      post '/activate/:id', authenticate: false do
        data = params.slice('displayname', 'username', 'email', 'password')
                 .merge(role: 'customer').transform_keys(&:to_sym)

        logger.info "Form data: #{data.inspect}"
        
        if (reg = user_registrations.find_active_by_id_and_key(params[:id], params['key'])).nil?
          render :activation_invalid
        elsif (errors = User.errors(data)).empty?
          User[data].tap do |user|
            logger.info "Storing user: #{user.inspect}"
            users.store!(user)
            current_user!(user)
          end
          redirect_to '/login'
        else
          render :account_activated, { registration: reg }
        end
      end

      get '/login' do
        render :login
      end

      post '/login' do
        user = users.find_user_and_authenticate(username: params['username'], password: params['password'])
        ref  = params['ref'].empty? ? '/' : params['ref']
        
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
          render json: { redirect: '/' }
        else
          redirect_to '/'
        end
      end

      def error(e)
        logger.error "#{e.message}"
        e.backtrace.each do |trace|
          logger.error "  #{trace}"
        end
        
        render :error
      end
    end
  end
end