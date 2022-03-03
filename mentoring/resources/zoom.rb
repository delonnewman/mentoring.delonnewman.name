# frozen_string_literal: true

module Mentoring
  # A resource for loading Zoom configuration
  class Zoom
    include El::Application::Resource

    attr_reader :client

    def load
      ::Zoom.configure do |config|
        config.api_key = app.settings[:zoom_api_key]
        config.api_secret = app.settings[:zoom_api_secret]
      end

      @client = ::Zoom.new
    end

    def create_meeting!(customer:, mentor:, start_at: Time.now)
      ZoomMeeting.create!(zoom_client, customer, mentor, start_at: start_at)
    end

    def meeting_for_session(session)
      session = session.is_a?(MentoringSession) ? session : find_by!(id: session)
      ZoomMeeting.from_session(zoom_client, session).tap do |meeting|
        meeting.fetch_data! unless session.ended?
      end
    end

    def delete_meeting!(session)
      ZoomMeeting.from_session(zoom_client, session).delete!
    end
  end
end
