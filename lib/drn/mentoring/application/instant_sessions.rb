module Drn
  module Mentoring
    class Application
      class InstantSessions < Controller
        get '/new' do |params|
          session_id = params['session_id']
        end

        # create session
        post '/' do
          # create database record session_id:UUID, stripe_session_id:String, started_at:Time, ended_at:Time 
          # session = sessions.create!(stripe_session_id: params['session_id'])
          # redirect_to session_path(session.session_id)
        end

        # show session
        get '/:id' do |params|
          # Display timer
          # Have a link to a Zoom Session
          # Display chat & shared code editor
        end

        # update session
        post '/:id' do
        end

        # end session
        delete '/:id' do |params|
          # set ended_at timestamp for session
          # mentor should be able to update timestamp
          # calculate quantity from started_at and ended_at
          # mentor okays the checkout
        end
      end
    end
  end
end