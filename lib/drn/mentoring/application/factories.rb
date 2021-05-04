# frozen_string_literal: true
module Drn
  module Mentoring
    class Application
      def products
        @products ||= ProductRepository.new
      end

      def sessions
        @sessions ||= SessionRepository.new
      end

      def users
        @users ||= UserRepository.new
      end
    end
  end
end
