module Drn
  module Mentoring
    # Represents the state of an instant session
    class Session < Entity
      require :instant_session_id, :checkout_session_id, :started_at

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
