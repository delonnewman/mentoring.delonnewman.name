# frozen_string_literal: true

module Mentoring
  # Represents mentoring products
  class Product < Application.Entity()
    include El::NumericUtils

    primary_key :id, :uuid

    has :name, String, display: { order: 0 }
    has :description, String
    has :image_path, String
    has :amount, Integer
    has :meta, Hash, serialize: true, default: EMPTY_HASH
    has :sort_order, Integer, default: 0

    belongs_to :rate
    def_delegator :rate, :subscription?

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

    def subscribed?(user:, products:)
      return false unless subscription? || user.nil?

      products.product_ids_by_customer(user).include?(id)
    end

    def should_disable?(user:, mentors:, products:)
      case type
      when :instant
        mentors.none?(&:available?)
      when :ongoing
        subscribed?(user: user, products: products)
      end
    end

    def type
      case name
      when 'Instant Help', 'Instant Conversation'
        :instant
      when 'Ongoing Mentoring'
        :ongoing
      end
    end

    def instant?
      type == :instant
    end

    def ongoing?
      type == :ongoing
    end

    # TODO: create a ProductRepository class
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

      def products_with_states(user:, mentors:)
        purchased = product_ids_by_customer(user)
        map do |p|
          p.merge(purchased: purchased.include?(p.id),
                  disabled: p.should_disable?(user: user, mentors: mentors, products: self))
        end
      end

      def subscribers
        db[:products]
          .join(:product_rates, id: :rate_id)
          .join(:users_products, product_id: Sequel[:products][:id])
          .join(:users, id: Sequel[:users_products][:user_id])
          .join(:user_roles, id: Sequel[:users][:role_id])
          .where(Sequel[:product_rates][:subscription] => true)
          .select_all(:users)
          .select_append(
            Sequel[:user_roles][:id].as('role[id]'),
            Sequel[:user_roles][:name].as('role[name]'),
            Sequel[:products][:id].as('product_id')
          )
          .map { |record| Framework::SqlUtils.build_entity(User, record) }
      end

      private

      def customer_products(user)
        user_id = user.is_a?(User) ? user.id : user
        dataset.join(:users_products, product_id: Sequel[:products][:id]).where(user_id: user_id)
      end
    end
  end
end
