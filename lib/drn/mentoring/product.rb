module Drn
  module Mentoring
    class Product < Entity
      require :product_id, :name, :description, :image_url, :price_id, :unit_amount, :recurring

      def recurring?
        !recurring.nil? && recurring != false
      end
      alias subscription? recurring?

      def price
        unit_amount.to_f / 100
      end

      def checkout_mode
        recurring? ? 'subscription' : 'setup'
      end
    end
  end
end
