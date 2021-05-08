module Drn
  module Mentoring
    # Represents the state of a mentoring session
    class MentoringSession < Entity
      has :id,                  String,                 required: false
      has :checkout_session_id, String
      has :status,              MentoringSessionStatus, resolve_with: { Integer => :id, String => :name }
      has :started_at,          Time,                   default: -> { Time.now }
      has :ended_at,            Time,                   required: false

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
