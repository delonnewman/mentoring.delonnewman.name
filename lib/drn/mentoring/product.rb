# frozen_string_literal: true

module Drn
  module Mentoring
    require_relative 'product/instant_help_policy'
    require_relative 'product/ongoing_mentoring_policy'

    # Represents mentoring products
    class Product < Framework::Entity
      include Framework::NumericUtils

      primary_key :id, :uuid

      has :name, String, display: { order: 0 }
      has :description, String
      has :image_path, String
      has :amount, Integer
      has :meta, Hash, serialize: true, default: EMPTY_HASH
      has :sort_order, Integer, default: 0

      belongs_to :rate
      def_delegator :rate, :subscription?

      repository do
        order_by :sort_order

        def subscribe(product, user)
          product = Product.ensure!(product)
          user = User.ensure!(user)
          db[:users_products].insert(product_id: product.id, user_id: user.id, created_at: Time.now)
        end

        def products_by_customer(user)
          customer_products(user).map(&SqlUtils.method(:build_entity).curry[entity_class])
        end

        def product_ids_by_customer(user)
          customer_products(user).select_map(Sequel[:products][:id])
        end

        def products_and_purchased_by_customer(user)
          purchased = product_ids_by_customer(user)
          map { |p| [p, purchased.include?(p.id)] }
        end

        def subscribers
          db[:products]
            .join(:product_rates, id: :rate_id)
            .join(:users_products, product_id: Sequel[:products][:id])
            .join(:users, id: Sequel[:users_products][:user_id])
            .join(:user_roles, id: Sequel[:users][:role_id])
            .where(Sequel[:product_rates][:subscription] => true)
            .select_all(:users)
            .select_append(Sequel[:user_roles][:id].as('role[id]'), Sequel[:user_roles][:name].as('role[name]'))
            .map { |record| Framework::SqlUtils.build_entity(User, record) }
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

      def price_rate
        dollars(amount / 100).per(rate.unit)
      end

      def price
        amount / 100
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
