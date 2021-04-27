module Drn
  module Mentoring
    class ProductRepository < Repository
      def initialize
        @products = Stripe::Product.list.map do |product|
          key      = "#{product.name.gsub(/\W+/, '_').upcase}_ID"
          price_id = ENV.fetch(key)
          price    = Stripe::Price.retrieve(price_id)
          Product[
            product_id:  product.id,
            name:        product.name,
            description: product.description,
            image_url:   product.images.first,
            price_key:   key,
            price_id:    price_id,
            unit_amount: price.unit_amount,
            recurring:  !price.recurring.nil?
          ]
        end
      end

      def each(&block)
        @products.each(&block)
        self
      end

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
