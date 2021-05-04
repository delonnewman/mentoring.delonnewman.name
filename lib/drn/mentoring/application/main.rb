# frozen_string_literal: true
module Drn
  module Mentoring
    class Application
      class Main < Controller
        use Rack::Session::Cookie, secret: ENV['MENTORING_SESSION_SECRET']
        #use Rack::MiniProfiler

        #use OmniAuth::Builder do
        #  provider :developer unless env == :production
        #end

        mount '/checkout', Checkout
        mount '/session',  InstantSessions

        get '/' do
          render :index
        end

        get '/login' do
          render :login
        end

        post '/login' do
          user = users.find_user_and_authenticate(username: params['username'], password: params['password'])

          if user
            current_user! user
            redirect_to '/'
          else
            status 401
            render :login
          end
        end

        post '/logout' do
          logout!
          redirect_to '/'
        end

        def current_user
          user_id = request.session[:current_user_id]
          return nil           unless user_id
          return @current_user if     @current_user

          @current_user = users.find_by(id: user_id)
        end

        def current_user!(user)
          request.session[:current_user_id] = user.id
          @current_user = user
        end

        def logout!
          request.session.delete(:current_user_id)
          @current_user = nil
        end
      end
    end
  end
end
