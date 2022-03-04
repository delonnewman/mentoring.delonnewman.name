# frozen_string_literal: true

module El
  # Authentication for applications
  module Authenticable
    def self.included(base)
      base.include(InstanceMethods)
      base.extend(ClassMethods)
    end

    module ClassMethods
      def find_user(&block)
        return @find_user unless block

        @find_user = block
      end
    end

    module InstanceMethods
      def current_user
        return @current_user if @current_user

        user_id = request.session[:current_user_id]
        return nil unless user_id

        self.current_user = instance_exec(user_id, &self.class.find_user)
      end

      def current_user=(user)
        request.session[:current_user_id] = user.id
        @current_user = user
      end

      def logout!
        request.session.delete(:current_user_id)
        @current_user = nil
      end

      # If no arguments are given return true if a user is authenticated
      # otherwise return false. If a role is specified with "as" return
      # true if the user is authenticated and is assigned to the given role
      # if the user is not assigned to the role return false, otherwise
      # return nil.
      #
      # @option as [String] a role name to test
      #
      # @return [Boolean, nil]
      def authenticated?(as: nil)
        return !!current_user if as.nil?

        current_user&.role?(as)
      end
    end
  end
end