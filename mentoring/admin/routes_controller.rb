module Mentoring
  module Admin
    class RoutesController < ApplicationController
      layout :admin

      def index
        render :index, with: { routes_list: app.routes }
      end
    end
  end
end
