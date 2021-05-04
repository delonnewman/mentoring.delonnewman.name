# frozen_string_literal: true
module Drn
  module Mentoring
    class Application
      class Main < Controller
        use Rack::Session::Cookie, domain: ENV['DOMAIN'], path: '/', secret: ENV['MENTORING_SESSION_SECRET']
        use Rack::MiniProfiler
        use Rack::Flash

        use OmniAuth::Builder do
          provider :developer unless env == :production
        end

        mount '/checkout', Checkout
        mount '/session',  InstantSessions

        #static '/' => root.join('public')

        get '/' do
          logger.info "Request session: #{request.session.inspect}"
          logger.info "Current user: #{request.session[:current_user_id].inspect}"
          if request.session[:current_user_id]
            render :index
          else
            redirect_to '/login'
          end
        end

        get '/login' do
          render :login
        end

        post '/login' do
          user = users.find_user_and_authenticate(username: params['username'], password: params['password'])

          logger.info "Authenticated user: #{user.inspect}"

          if user
            request.session[:current_user_id] = user.id
            logger.info "Request session: #{request.session.inspect}"
            redirect_to '/'
          else
            render :login, status: 401
          end
        end

        def current_user(user = nil)
          @current_user = user if user
          @current_user
        end
      end
    end
  end
end
