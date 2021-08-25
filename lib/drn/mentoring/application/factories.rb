# frozen_string_literal: true
module Drn
  module Mentoring
    class Application
      def products
        Product.repository
      end

      def mentoring_sessions
        MentoringSession.repository
      end

      def users
        User.repository
      end

      def user_registrations
        UserRegistration.repository
      end

      def messenger
        @messenger ||= ApplicationMessenger.new(self)
      end

      def create_zoom_meeting!(customer:, mentor:)
        ZoomMeeting.create!(zoom_client, customer, mentor)
      end

      def zoom_meeting(session)
        session = session.is_a?(MentoringSession) ? session : find_by!(id: session)
        ZoomMeeting.from_session(zoom_client, session).tap do |meeting|
          meeting.fetch_data! unless session.ended?
        end
      end

      def delete_zoom_meeting!(session)
        ZoomMeeting.from_session(zoom_client, session).delete!
      end

      def default_mentor
        @default_mentor ||= users.find_by!(username: default_mentor_username)
      end
    end
  end
end
