module Drn
  module Mentoring
    class SessionRepository < Repository
      def initialize
        super(db[:sessions], Session)
      end

      def create!(checkout_session_id:)
        record = { instant_session_id: SecureRandom.uuid, checkout_session_id: checkout_session_id, started_at: Time.now }
        @dataset.insert(record)
        Session[record]
      end
    end
  end
end
