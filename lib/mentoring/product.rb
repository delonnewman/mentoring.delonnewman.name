# frozen_string_literal: true

module Mentoring
  # Represents mentoring products
  class Product < Application.Entity()
    primary_key :id, :uuid

    has :name,        String, display: { order: 0 }
    has :description, String
    has :image_path,  String
    has :amount,      Integer
    has :meta,        Hash,    serialize: true, default: EMPTY_HASH
    has :sort_order,  Integer, default: 0

    belongs_to :rate
    def_delegator :rate, :subscription?

    alias to_s name

    def disabled?(*args)
      policy&.disabled?(*args)
    end

    def price_rate
      price.per(rate.unit)
    end

    def price
      amount.cents.in(:dollars)
    end

    def discounted_price
      price / 2
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
  end
end
