# frozen_string_literal: true
module Drn
  module Mentoring
    class Application
      def products
        Product.repository
      end

      def mentoring_sessions
        MentoringSession.repository
      end

      def users
        User.repository
      end

      def account_messenger
        @account_messenger ||= AccountMessenger.new(Drn::Mentoring.app)
      end
    end
  end
end
