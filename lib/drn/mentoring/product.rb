module Drn
  module Mentoring
    class Product < Entity
      primary_key :id, :uuid

      has :name,        String, display: { order: 0 }
      has :description, String
      has :image_path,  String
      has :amount,      Integer
      has :meta,        Hash,        required: false, serialize: true
      has :sort_order,  Integer,     default: 0

      belongs_to :rate, ProductRate
      def_delegator :rate, :subscription?

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
