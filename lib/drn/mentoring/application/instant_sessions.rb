module Drn
  module Mentoring
    class Application
      class InstantSessions < Controller
        get '/new' do |params|
          session_id = params['session_id']
          # create database record session_id:UUID, stripe_session_id:String, started_at:Time, ended_at:Time 
          # session = sessions.create!(stripe_session_id: params['session_id'])
          # redirect_to session_path(session.session_id)
        end

        get '/:id' do |params|
          # Display timer
          # Have a link to a Zoom Session
          # And a visual studio code session
        end
      end
    end
  end
end
