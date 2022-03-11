# frozen_string_literal: true

module Mentoring
  # Represents the state of a mentoring session
  class Session < Application.Entity()
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
        if duration <= ~5.minutes
          0.dollars
        else
          product.price_rate * duration
        end
      end
    end
  end
end
