# frozen_string_literal: true

module Drn
  module Mentoring
    # Represents the state of a mentoring session
    class MentoringSession < Framework::Entity
      include Framework::TimeUtils
      include Framework::NumericUtils

      primary_key :id, :uuid

      has :checkout_session_id, String,   required: false
      has :zoom_meeting_id,     Integer,  required: false
      has :started_at,          Time,     default: -> { Time.now }
      has :ended_at,            Time,     required: false
      has :paid_at,             Time,     required: false
      has :from_subscription,   :boolean, required: false

      # TODO: add a way to establish a looser relationship or
      # to select the fields that will be loaded (maybe both?).
      #
      # Also need to add to repository aspects of component attributes
      # if the field is not required it should be an outer join.
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

      def duration
        return nil unless ended?

        seconds(ended_at - started_at).as(:minutes)
      end

      def cost
        if duration <= ~minutes(5)
          dollars(0)
        else
          product.price_rate * duration
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
end
