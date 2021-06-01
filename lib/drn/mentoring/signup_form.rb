module Drn
  module Mentoring
    class SignupForm
      def initialize(user)
        @user = user
      end

      def errors
        User.errors(@user)
      end
    end
  end
end
