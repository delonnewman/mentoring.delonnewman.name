# frozen_string_literal: true

module Drn
  module Mentoring
    class Main < Framework::Controller
      # Routes for mentoring sessions
      class MentoringSessions < Framework::Controller
        include Framework::Authenticable
        include Framework::TimeUtils

        get '/new' do
          # start / cancel buttons with some instructions
          render :new, with: { checkout_session_id: params['session_id'], product_id: params['product_id'] }
        end

        # create session
        post '/' do
          customer = app.users.find_by!(id: params['customer_id'])
          meeting = app.create_zoom_meeting!(customer: current_user, mentor: app.default_mentor)

          session = app.mentoring_sessions.create!(
            checkout_session_id: params['checkout_session_id'],
            customer: customer,
            mentor: app.default_mentor,
            zoom_meeting_id: meeting.id,
            product: app.products.find_by!(id: params['product_id'])
          )

          app.messenger.notify!(session, about: :new_session)

          redirect_to session_path(session)
        end

        # show session
        get '/:id' do
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
        post '/:id' do
          session = app.mentoring_sessions.update!(params[:id], params['session'])

          redirect_to session_path(session)
        end

        # end session
        delete '/:id' do
          # set ended_at timestamp for session
          # mentor should be able to update timestamp
          # calculate quantity from started_at and ended_at
          # mentor okays the checkout
          session = app.mentoring_sessions.end!(params[:id])
          app.delete_zoom_meeting!(session)

          redirect_to session_path(session)
        end

        post '/:id/bill' do
          session = app.mentoring_sessions
                       .find_by!(id: params[:id])
                       .merge(cost: Float(params.dig('session', 'amount'))) # TODO: improve entity coersion

          app.billing.bill_mentoring_session!(session)

          redirect_to session_path(session)
        end

        post '/:id/amount' do
          session = app.mentoring_sessions.find_by(id: params[:id])
          duration = minutes(Float(params['duration']))

          if session.nil?
            json.error("Invalid product #{params['product_id'].inspect}")
          else
            json.success(amount: session.merge(duration: duration).cost.magnitude.to_f.round(2))
          end
        end

        def session_path(session)
          "/session/#{session.id}"
        end
      end
    end
  end
end
