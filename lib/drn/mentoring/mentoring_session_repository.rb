module Drn
  module Mentoring
    class MentoringSessionRepository < Repository
      def create!(checkout_session_id:)
        record = { id: SecureRandom.uuid, checkout_session_id: checkout_session_id, started_at: Time.now }
        logger.info "CREATE session with: #{record.inspect}"
        dataset.insert(record)
        factory[record]
      end

      def update!(id, data)
        @dataset.where(id: id).update(data)
        find_by!(id: id)
      end

      def end!(id)
        update!(id, ended_at: Time.now)
      end

      ALL_QUERY = <<~SQL
        select mentoring_sessions.*,
               mentoring_session_statuses.name as status_name
          from mentoring_sessions
    inner join mentoring_session_statuses on mentoring_sessions.status_id = mentoring_session_statuses.id
      SQL

      def all(&block)
        run ALL_QUERY do |records|
          records.map do |record|
            factory[nest_component_attributes(record, 'status')].tap do |entity|
              block.call(entity) if block
            end
          end
        end
      end
      alias each all

      ONE_QUERY = <<~SQL
        select mentoring_sessions.*,
               mentoring_session_statuses.name as status_name
          from mentoring_sessions
    inner join mentoring_session_statuses on mentoring_sessions.status_id = mentoring_session_statuses.id
          /* where */
         limit 1
      SQL

      ATTRIBUTE_MAP = Hash.new { |_, key| key }
      ATTRIBUTE_MAP[:id] = :'mentoring_sessions.id'

      def find_by(predicates)
        preds       = predicates.transform_keys(&ATTRIBUTE_MAP)
        qstr, binds = sql_where(preds)
        query       = ONE_QUERY.sub('/* where */', qstr)
        records     = run(query, *binds)
        return nil if records.empty?
        factory[nest_component_attributes(records.first, 'status')]
      end
    end
  end
end
