module Drn
  module Mentoring
    class Application
      class InstantSessions < Controller
        get '/new' do |params|
          # start / cancel buttons with some instructions
          render :new, with: { checkout_session_id: params['session_id'] }
        end

        # create session
        post '/' do |params|
          # create database record session_id:UUID, stripe_session_id:String, started_at:Time, ended_at:Time 
          session = sessions.create!(checkout_session_id: params['checkout_session_id'])
          redirect_to session_path(session)
        end

        # show session
        get '/:id' do |params|
          # Display timer
          # Have a link to a Zoom Session
          # Display chat & shared code editor
          render :show, with: { session: sessions.find_by!(instant_session_id: params[:id]) }
        end

        # update session
        post '/:id' do |params|
          session = sessions.update!(params[:id], params['session'])
          redirect_to session_path(session)
        end

        # end session
        delete '/:id' do |params|
          # set ended_at timestamp for session
          # mentor should be able to update timestamp
          # calculate quantity from started_at and ended_at
          # mentor okays the checkout
          session = sessions.end!(params[:id])
          redirect_to session_path(session)
        end

        def session_path(session)
          "/session/#{session.instant_session_id}"
        end
      end
    end
  end
end
