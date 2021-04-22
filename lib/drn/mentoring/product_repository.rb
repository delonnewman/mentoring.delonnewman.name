module Drn
  module Mentoring
    class ProductRepository < Repository
      def initialize
        super(App.db[:products], Product)
      end

      def by_id(id)
        @dataset.first { product_id == id }
      end
    end
  end
end
