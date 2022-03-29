module Mentoring
  module Main
    class DashboardController < ApplicationController
      def index
        render Main::DashboardView
      end
    end
  end
end
