module Drn
  module Mentoring
    class SessionRepository < Repository
      def initialize
        super(db[:sessions], Session)
      end

      def create!(checkout_session_id:)
        record = { instant_session_id: SecureRandom.uuid, checkout_session_id: checkout_session_id, started_at: Time.now }
        logger.info "CREATE session with: #{record.inspect}"
        @dataset.insert(record)
        Session[record]
      end

      def update!(id, data)
        @dataset.where(instant_session_id: id).update(data)
        find_by!(instant_session_id: id)
      end

      def end!(id)
        update!(id, ended_at: Time.now)
      end
    end
  end
end
