# frozen_string_literal: true

module Mentoring
  module Sessions
    # A controller for creating viewing and ending mentoring sessions
    class SessionsController < ApplicationController
      # include El::TimeUtils

      # start / cancel buttons with some instructions
      def new
        render :new, with: { checkout_session_id: params[:session_id], product_id: params[:product_id] }
      end

      # Display timer
      # Have a link to a Zoom Session
      # Display chat & shared code editor
      def show
        session = app.sessions.find_by!(id: params[:id])

        if session.viewable_by?(current_user)
          meeting = app.video_conferencing.meeting_for_session(session)

          render :show, with: { session: session, meeting: meeting }
        else
          render :unauthorized
        end
      end

      def update
        session = app.sessions.update!(params[:id], params[:session])

        redirect_to routes.session_path(session)
      end

      # Set ended_at timestamp for session
      # mentor should be able to update timestamp
      # calculate quantity from started_at and ended_at
      # mentor okays the checkout
      def end
        session = app.sessions.end!(params[:id])
        app.video_conferencing.delete_meeting!(session)

        redirect_to routes.session_path(session)
      end

      # Activate session & create video conferencing meeting
      def create
        customer = app.users.find_by!(id: params[:customer_id])
        session  = create_session(customer, create_meeting(start_time))

        deliver! :new_session, session, with: Sessions::Messenger
        redirect_to routes.session_path(session)
      end

      private

      def start_time
        Time.iso8601(params.fetch(:start_at) { Time.now.iso8601 })
      end

      def create_meeting(start_time)
        app.video_conferencing.create_meeting!(
          customer: current_user,
          mentor: app.users.default_mentor,
          start_at: start_time
        )
      end

      def create_session(customer, meeting)
        app.sessions.create!(
          checkout_session_id: params[:checkout_session_id],
          customer: customer,
          mentor: app.users.default_mentor,
          zoom_meeting_id: meeting.id,
          product: app.products.find_by!(id: params[:product_id])
        )
      end
    end
  end
end
