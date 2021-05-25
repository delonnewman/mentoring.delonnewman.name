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

      def delete_where!(predicates)
        qstr, binds = sql_where(predicates)
        query       = "delete from products #{qstr}"
        run(query, *binds)
        self
      end

      ALL_QUERY = <<~SQL
          select p.*,
                 r.name as rate_name,
                 r.description as rate_description,
                 r.subscription as rate_subscription
            from products p inner join product_rates r on p.rate_id = r.id order by sort_order
      SQL

      def all(&block)
        run ALL_QUERY do |records|
          records.map do |record|
            Product[nest_component_attributes(reconstitute_record(record), 'rate')].tap do |product|
              block.call(product) if block
            end
          end
        end
      end
      alias each all

      ONE_QUERY = <<~SQL
        select products.*,
               product_rates.name as rate_name,
               product_rates.description as rate_description,
               product_rates.subscription as rate_subscription
          from products
    inner join product_rates on products.rate_id = product_rates.id
          /* where */
         limit 1
      SQL

      ATTRIBUTE_MAP = Hash.new { |_, key| key }
      ATTRIBUTE_MAP[:id] = :'products.id'
      ATTRIBUTE_MAP[:name] = :'products.name'
      ATTRIBUTE_MAP[:description] = :'products.description'
      ATTRIBUTE_MAP[:subscription] = :'products.subscription'

      def find_by(predicates)
        preds       = predicates.transform_keys(&ATTRIBUTE_MAP)
        qstr, binds = sql_where(preds)
        query       = ONE_QUERY.sub('/* where */', qstr)
        records     = run(query, *binds)
        return nil if records.empty?
        r = nest_component_attributes(reconstitute_record(records.first), 'rate')
        factory[r]
      end
    end
  end
end
