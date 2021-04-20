module Drn
  module Mentoring
    class Product < HashDelegator
      require :product_id, :name, :image, :price, :unit
    end
  end
end
