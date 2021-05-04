module Drn
  module Mentoring
    module Recurrable
      def recurring?
        !recurring.nil? && recurring != false
      end
      alias subscription? recurring?
    end
  end
end
