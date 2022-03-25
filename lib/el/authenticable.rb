# frozen_string_literal: true

module El
  # Authentication for applications
  module Authenticable
    def self.call(app, request)
      return request unless (user_id = request.session[:current_user_id])

      request.include_params(current_user: app.users.find_by!(id: user_id))
    end

    module InstanceMethods
      def current_user
        request.params[:current_user]
      end

      def login!(user)
        request.session[:current_user_id] = user.id
      end

      def logout!
        request.session.delete(:current_user_id)
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
