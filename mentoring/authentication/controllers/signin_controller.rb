# frozen_string_literal: true

module Mentoring
  module Authentication
    class SigninController < ApplicationController
      layout :main

      def index
        render :login
      end

      def create
        user = app.users.find_user_and_authenticate(username: params[:username], password: params[:password])
        ref  = params[:ref].blank? ? routes.dashboard_path : params[:ref]

        if user
          self.current_user = user
          redirect_to ref
        else
          render :login, status: 401
        end
      end

      def remove
        logout!

        if request.content_type == 'application/javascript'
          render json: { redirect: routes.root_path }
        else
          redirect_to routes.root_path
        end
      end
    end
  end
end
