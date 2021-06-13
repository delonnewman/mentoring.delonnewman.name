# frozen_string_literal: true

module Drn
  module Mentoring
    require_relative 'product/instant_help_policy'
    require_relative 'product/ongoing_mentoring_policy'

    # Represents mentoring products
    class Product < Entity
      primary_key :id, :uuid

      has :name,        String, display: { order: 0 }
      has :description, String
      has :image_path,  String
      has :amount,      Integer
      has :meta,        Hash,    serialize: true, default: EMPTY_HASH
      has :sort_order,  Integer, default: 0

      has_many :users
      belongs_to :rate
      def_delegator :rate, :subscription?

      repository do
        order_by :sort_order
      end

      alias to_s name

      def policy
        return @policy if @policy

        case name
        when 'Instant Help', 'Instant Conversation'
          @policy = InstantHelpPolicy.new(product: self, mentoring_sessions: MentoringSession.repository)
        when 'Ongoing Mentoring'
          @policy = OngoingMentoringPolicy.new(product: self)
        end
      end

      def disabled?(*args)
        policy&.disabled?(*args)
      end

      def price
        amount.to_f / 100
      end

      def price_id
        meta.fetch(:stripe_price_id)
      end

      def checkout_mode
        subscription? ? 'subscription' : 'setup'
      end
    end
  end
end
