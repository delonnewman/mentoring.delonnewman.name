module Drn
  module Mentoring
    class Application
      def products
        @products ||= Stripe::Product.list
      end
    end
  end
end
