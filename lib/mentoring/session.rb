# frozen_string_literal: true

module Mentoring
  # Represents the state of a mentoring session
  class Session < Application.Entity()
    include El::TimeUtils
    include El::NumericUtils

    primary_key :id, :uuid

    has :zoom_meeting_id,     Integer
    has :checkout_session_id, String,   required: false
    has :started_at,          Time,     default: -> { Time.now }
    has :ended_at,            Time,     required: false
    has :paid_at,             Time,     required: false
    has :billed_at,           Time,     required: false
    has :from_subscription,   :boolean, required: false

    belongs_to :mentor,   type: User
    belongs_to :customer, type: User
    belongs_to :product,  type: Product

    def viewable_by?(current_user)
      current_user.id == dig(:customer, :id) || current_user.id == dig(:mentor, :id)
    end

    def ended?
      !incomplete?
    end

    def incomplete?
      ended_at.nil?
    end

    def unpaid?
      !from_subscription? && paid_at.nil?
    end

    def paid?
      !unpaid?
    end

    def billed?
      !billed_at.nil?
    end

    def duration
      return nil unless ended?

      fetch :duration do
        seconds(ended_at - started_at).as(:minutes)
      end
    end

    def cost
      return nil if duration.nil?

      fetch :cost do
        if duration <= ~minutes(5)
          dollars(0)
        else
          product.price_rate * duration
        end
      end
    end

    TIME_LEFT_QUERY = <<~SQL
        select *
          from mentoring_sessions
         where customer_id = :customer_id
      group by date_part('month', started_at)
    SQL

    repository do
      def time_left_on_subscription(user)
        db[:mentoring_sessions].fetch(TIME_LEFT_QUERY, customer_id: user.id)
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
          .map(&method(:build_entity))
      end
    end
  end
end
