# frozen_string_literal: true

module Mentoring
  # A collection of Session objects and methods on them
  class SessionRepository < El::Repository
    TIME_LEFT_QUERY = <<~SQL
        select *
          from sessions
         where customer_id = :customer_id
      group by date_part('month', started_at)
    SQL

    def time_left_on_subscription(user)
      db[:sessions].fetch(TIME_LEFT_QUERY, customer_id: user.id)
    end

    def end!(id)
      update!(id, ended_at: Time.now)
      find_by!(id: id)
    end

    def active_sessions(for_mentor:)
      dataset.where(Sequel.~(ended_at: nil)).and(mentor_id: for_mentor.id)
    end

    def active_and_recently_ended_sessions_where(predicates)
      dataset
        .where(ended_at: nil)
        .or { ended_at > Date.today.to_time }
        .or(paid_at: nil)
        .where(predicates)
        .map(&method(:entity))
    end
  end
end
