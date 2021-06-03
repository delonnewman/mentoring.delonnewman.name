module Drn
  module Mentoring
    # Represents the state of a mentoring session
    class MentoringSession < Entity
      primary_key :id, :uuid

      has :checkout_session_id, String
      has :started_at,          Time, default: ->{ Time.now }
      has :ended_at,            Time, required: false

      belongs_to :mentor,   User, default: 'delon'
      belongs_to :customer, User

      repository do
        def end!(id)
          update!(id, ended_at: Time.now)
        end
      end

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
