module Drn
  module Mentoring
    class AccountMessenger < Mailer
      layout :mailer
      
      def signup(user)
        mail :signup, to: user.email, subject: 'Thank you for giving us a try! Please complete your registration.'
      end
    end
  end
end
