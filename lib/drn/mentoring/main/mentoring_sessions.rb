# frozen_string_literal: true

module Drn
  module Mentoring
    class Main < Framework::Controller
      class MentoringSessions < Framework::Controller
        include Framework::Authenticable

        get '/new' do |params|
          # start / cancel buttons with some instructions
          render :new, with: { checkout_session_id: params['session_id'] }
        end

        # create session
        post '/' do |params|
          meeting = app.create_zoom_meeting!(customer: current_user, mentor: app.default_mentor)

          session = app.mentoring_sessions.create!(
            checkout_session_id: params['checkout_session_id'],
            customer: current_user,
            mentor: app.default_mentor,
            zoom_meeting_id: meeting.id
          )

          app.messenger.notify!(session, about: :new_session)

          redirect_to session_path(session)
        end

        # show session
        get '/:id' do |params|
          # Display timer
          # Have a link to a Zoom Session
          # Display chat & shared code editor
          session = app.mentoring_sessions.find_by!(id: params[:id])

          if session.viewable_by?(current_user)
            render :show, with: { session: session, zoom_meeting: app.zoom_meeting(session) }
          else
            render :unauthorized
          end
        end

        # update session
        post '/:id' do |params|
          session = app.mentoring_sessions.update!(params[:id], params['session'])
          redirect_to session_path(session)
        end

        # end session
        delete '/:id' do |params|
          # set ended_at timestamp for session
          # mentor should be able to update timestamp
          # calculate quantity from started_at and ended_at
          # mentor okays the checkout
          session = app.mentoring_sessions.end!(params[:id])
          app.delete_zoom_meeting!(session)
          redirect_to session_path(session)
        end

        def session_path(session)
          "/session/#{session.id}"
        end
      end
    end
  end
end
