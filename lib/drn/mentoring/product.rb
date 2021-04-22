module Drn
  module Mentoring
    class Product < Entity
      require :product_id, :name, :image, :price, :recurring

      def recurring?
        !recurrent.nil?
      end
    end
  end
end
