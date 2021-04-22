module Drn
  module Mentoring
    class Application
      def products
        @products ||= ProductRepository.new
      end
    end
  end
end
