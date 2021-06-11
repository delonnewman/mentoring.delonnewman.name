# frozen_string_literal: true

module Drn
  module Mentoring
    require_relative 'instant_help_policy'

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
      def_delegator :policy, :disabled?

      repository do
        def by_price_id(price_id)
          find { |product| product.price_id == price_id }
        end

        def by_price_id!(price_id)
          by_price_id(price_id) or raise "Couldn't find product with price_id #{price_id.inspect}"
        end

        def by_id(id)
          find { |product| product.product_id == id }
        end
      end

      alias to_s name

      def policy
        case name
        when 'Instant Help', 'Instant Coversation'
          InstantHelpPolicy.new(product: self, mentoring_sessions: MentoringSession.repository)
        end
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
