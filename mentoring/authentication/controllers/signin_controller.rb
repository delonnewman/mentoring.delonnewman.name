# frozen_string_literal: true

module Mentoring
  module Authentication
    class SigninController < El::Controller
      def index
        render :login
      end

      def create
        user = app.users.find_user_and_authenticate(username: params[:username], password: params[:password])
        ref  = params[:ref].blank? ? app.routes.dashboard_path : params[:ref]

        if user
          self.current_user = user
          redirect_to ref
        else
          render :login, status: 401
        end
      end

      def remove
        router.logout!

        if request.content_type == 'application/javascript'
          render json: { redirect: app.routes.root_path }
        else
          redirect_to app.routes.root_path
        end
      end
    end
  end
end
