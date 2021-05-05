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

      ALL_QUERY = <<~SQL
          select p.*,
                 r.name as rate_name,
                 r.description as rate_description,
                 r.subscription as rate_subscription
            from products p inner join product_rates r on p.rate_id = r.id
      SQL

      def all(&block)
        run ALL_QUERY do |records|
          records.map do |record|
            attrs = record.reduce({}) do |h, (key, value)|
              if key.start_with?('rate')
                h[:rate] ||= {}
                k = key.name.sub('rate_', '').to_sym
                h[:rate][k] = value
              else
                h[key] = value
              end
              h
            end
            Product[attrs].tap do |product|
              block.call(product) if block
            end
          end
        end
      end
      alias each all
    end
  end
end
