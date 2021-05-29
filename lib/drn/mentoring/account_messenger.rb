module Drn
  module Mentoring
    class AccountMessenger < Mailer
      layout :mailer
      
      def signup
        render :signup
      end
    end
  end
end
