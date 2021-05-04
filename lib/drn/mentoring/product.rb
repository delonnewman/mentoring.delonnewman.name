module Drn
  module Mentoring
    class Product < Entity
      include Recurrable
      has :product_id,  :uuid
      has :name,        String
      has :description, String
      has :amount,      Integer
      has :rate,        ProductRate

      def_delegator :rate, :recurring?

      def price
        amount.to_f / 100
      end

      def checkout_mode
        recurring? ? 'subscription' : 'setup'
      end
    end
  end
end
