module Mentoring
  module Authentication
    class ActivationController < ApplicationController
      layout :main

      def show
        if (reg = app.user_registrations.find_active_by_id_and_key(params[:id], params[:key]))
          render :account_activated, with: { registration: reg }
        else
          render :activation_invalid
        end
      end

      def update
        data = params.slice(:displayname, :username, :email, :password)
                     .merge(role: 'customer')
                     .transform_keys(&:to_sym)

        logger.info "Form data: #{data.inspect}"

        if (reg = app.user_registrations.find_active_by_id_and_key(params[:id], params[:key])).nil?
          render :activation_invalid
        elsif User.errors(data).empty?
          User[data].tap do |user|
            logger.info "Storing user: #{user.inspect}"
            app.users.store!(user)
            self.current_user = user
          end
          redirect_to routes.login_path
        else
          render :account_activated, { registration: reg }
        end
      end
    end
  end
end
