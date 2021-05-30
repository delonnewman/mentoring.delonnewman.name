# frozen_string_literal: true
module Drn
  module Mentoring
    class Application
      class Main < AuthenticatedController
        use Rack::Session::Cookie, secret: Mentoring.app.session_secret

        static '/' => 'public'
        
        mount '/checkout', Checkout
        mount '/session',  MentoringSessions
        mount '/users',    Users

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
          user = User[username: params['username'], email: params['email'], role: 'customer']

          if (errors = User.errors(user)).empty?
            users.store!(user)
            account_messenger.signup(user)
            redirect_to '/'
          else
            render :signup, with: { errors: errors }
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
      end
    end
  end
end
