module Drn
  module Mentoring
    class ProductRepository < Repository
      def initialize
        super(App.db[:products], Product)
      end

      def by_id(product_id)
        @dataset.first { id == product_id }
      end
    end
  end
end
