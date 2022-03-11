# frozen_string_literal: true

module Mentoring
  module Main
    class Controller < El::Controller
      def index
        render Main::IndexView
      end

      def state
        state = { authenticated: authenticated? }

        render js: "Mentoring = {}; Mentoring.state = #{state.to_json}"
      end

      def dashboard
        render Main::DashboardView
      end
    end
  end
end
