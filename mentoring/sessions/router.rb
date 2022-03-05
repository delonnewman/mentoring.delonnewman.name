# frozen_string_literal: true

module Mentoring
  module Sessions
    # Routes for mentoring sessions
    class Router < Application.Router()
      include El::TimeUtils

      get '/new' do
        # start / cancel buttons with some instructions
        render :new, with: { checkout_session_id: params['session_id'], product_id: params['product_id'] }
      end

      # create session
      post '/' do
        customer = app.users.find_by!(id: params['customer_id'])
        start_time = Time.iso8601(params.fetch('start_at') { Time.now.iso8601 })

        meeting = app.video_conferencing.create_meeting!(
          customer: current_user,
          mentor: app.default_mentor,
          start_at: start_time
        )

        session = app.sessions.create!(
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
        session = app.sessions.find_by!(id: params[:id])

        if session.viewable_by?(current_user)
          render :show, with: {
            session: session,
            meeting: app.video_conferencing.meeting_for_session(session)
          }
        else
          render :unauthorized
        end
      end

      # update session
      post '/:id' do
        session = app.sessions.update!(params[:id], params['session'])

        redirect_to session_path(session)
      end

      # end session
      delete '/:id' do
        # set ended_at timestamp for session
        # mentor should be able to update timestamp
        # calculate quantity from started_at and ended_at
        # mentor okays the checkout
        session = app.sessions.end!(params[:id])
        app.video_conferencing.delete_meeting!(session)

        redirect_to session_path(session)
      end

      post '/:id/bill' do
        session = app.sessions
                     .find_by!(id: params[:id])
                     .merge(cost: Float(params.dig('session', 'amount'))) # TODO: improve entity coersion

        app.billing.bill_session!(session)

        redirect_to session_path(session)
      end

      post '/:id/amount' do
        session = app.sessions.find_by(id: params[:id])
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
