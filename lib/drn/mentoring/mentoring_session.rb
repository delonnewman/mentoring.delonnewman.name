module Drn
  module Mentoring
    # Represents the state of a mentoring session
    class MentoringSession < Entity
      primary_key :id, String

      has :checkout_session_id, String
      has :started_at,          Time, default: -> { Time.now }
      has :ended_at,            Time, required: false

      belongs_to :status, MentoringSessionStatus

      def complete?
        !incomplete?
      end
      alias ended? complete?

      def incomplete?
        ended_at.nil?
      end
    end
  end
end
