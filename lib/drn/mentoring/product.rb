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
          db[:users_products].insert(product_id: product.id, user_id: user.id, created_at: Time.now)
        end

        def of_customer(user)
          customer_products(user).map(&SqlUtils.method(:build_entity).curry[entity_class])
        end

        def ids_of_customer(user)
          customer_products(user).select_map(Sequel[:products][:id])
        end

        private

        def customer_products(user)
          user_id = user.is_a?(User) ? user.id : user
          dataset.join(:users_products, product_id: Sequel[:products][:id]).where(user_id: user_id)
        end
      end

      alias to_s name

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

      def policy
        @policy ||= _policy
      end

      private

      def _policy
        case name
        when 'Instant Help', 'Instant Conversation'
          InstantHelpPolicy.new(self, MentoringSession.repository)
        when 'Ongoing Mentoring'
          OngoingMentoringPolicy.new(self)
        end
      end
    end
  end
end
