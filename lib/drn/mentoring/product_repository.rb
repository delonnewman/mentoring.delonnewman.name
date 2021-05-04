module Drn
  module Mentoring
    class ProductRepository < Repository
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
  end
end
