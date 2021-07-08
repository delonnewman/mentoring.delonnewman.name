# frozen_string_literal: true

module Drn
  module Mentoring
    require_relative 'product/instant_help_policy'
    require_relative 'product/ongoing_mentoring_policy'

    # Represents mentoring products
    class Product < Entity
      primary_key :id, :uuid

      has :name, String, display: { order: 0 }
      has :description, String
      has :image_path, String
      has :amount, Integer
      has :meta, Hash, serialize: true, default: EMPTY_HASH
      has :sort_order, Integer, default: 0

      has_many :users, join_table: :users_products
      belongs_to :rate
      def_delegator :rate, :subscription?

      repository do
        order_by :sort_order

        def subscribe(product, user)
          product = Product.ensure!(product)
          user = User.ensure!(user)
          db[:users_products].insert(product_id: product.id, user_id: user.id)
        end
      end

      alias to_s name

      def policy
        return @policy if @policy

        case name
        when 'Instant Help', 'Instant Conversation'
          @policy = InstantHelpPolicy.new(self, mentoring_sessions: MentoringSession.repository)
        when 'Ongoing Mentoring'
          @policy = OngoingMentoringPolicy.new(self)
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
